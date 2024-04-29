# typed: strict
require "sorbet-runtime"
require_relative "pass"
require_relative "il"
require_relative "graph"
require_relative "analysis/analysis"
require_relative "analysis/bb"
require_relative "analysis/cfg"
require_relative "analysis/live_vars"
require_relative "analysis/dominators"
require_relative "analysis/dom_tree"
require_relative "analysis/dom_frontiers"

# The SSA pass transforms a CFG into SSA form by optimally  inserting phi
# functions at join nodes and renaming IDs with unique subscripts.
class SSA < Pass
  extend T::Sig

  include Analysis

  sig { override.returns(String) }
  def id
    "ssa"
  end

  sig { override.returns(String) }
  def description
    "Transform a CFG into SSA form"
  end

  sig { params(cfg: CFG).void }
  # Construct a new SSA pass.
  #
  # @param [CFG] cfg The CFG to transform.
  def initialize(cfg)
    @cfg = cfg

    # define some hashes and sets ahead of time for use later
    # NOTE: these constructions will be overwritten on run but thats ok for now
    @globals = T.let(Set[], T::Set[String])
    @global_types = T.let(Hash.new, T::Hash[String, IL::Type])
    @blocks = T.let(Hash.new, T::Hash[String, T::Set[BB]])
    @df_facts = T.let(CFGFacts.new(cfg), CFGFacts[BB])
  end

  sig { void }
  # Run the SSA transformation on the CFG. It will be modified in place.
  def run
    # find and split all critical edges
    critical_edges = find_critical_edges
    critical_edges.each { |e|
      split_edge(e)
    }

    # run dominators, dom tree, and dom frontiers analysis
    dominators = Dominators.new(@cfg)
    dom_cfg_facts = dominators.run

    dom_tree = DomTree.new(dom_cfg_facts)

    dom_frontiers = DomFrontiers.new(@cfg, dom_tree)
    @df_facts = dom_frontiers.run

    # find global names and add phi functions
    find_globals
    rewrite_with_phi_funcs

    # rename everything to have proper subscripts
    rename_globals(dom_tree)
  end

  private

  sig { params(edge: Graph::Edge[BB]).void }
  def split_edge(edge)
    # delete old edge
    @cfg.delete_edge(edge)

    # create new block in the middle
    new_id = @cfg.max_block_id + 1
    new_block = BB.new(new_id, stmt_list: [])
    @cfg.add_node(new_block)

    # if old "to" was a true_branch, move that status to "new_block"
    new_block.true_branch = edge.to.true_branch
    edge.to.true_branch = false

    # create new edges to and from the new block
    @cfg.add_edge(Graph::Edge.new(edge.from, new_block))
    @cfg.add_edge(Graph::Edge.new(new_block, edge.to))
  end

  sig { returns(T::Array[Graph::Edge[BB]]) }
  def find_critical_edges
    critical_edges = []

    @cfg.each_edge { |e|
      if @cfg.predecessors_length(e.to) > 1 and
         @cfg.successors_length(e.from) > 1
        critical_edges.push(e)
      end
    }

    return critical_edges
  end

  sig { void }
  def rewrite_with_phi_funcs
    # for each id in globals
    @globals.each { |name|
      work_list = @blocks[name]
      processed = @blocks[name]

      if not work_list
        work_list = Set[]
      end

      if not processed
        processed = Set[]
      end

      # for each block in work list
      work_list.each { |b|
        # for each block in DF(b)
        @df_facts.get_fact(:df, b).each { |d|
          # if d has no phi function for id...
          existing_phi = find_phi(d, name)
          if existing_phi # skip because it has a phi already
            next
          end

          # ...prepend phi for id in d and add d to work list
          phi = IL::Definition.new(T.unsafe(@global_types[name]),
                                   IL::ID.new(name),
                                   IL::Phi.new([])) # ids will be filled later
          d.stmt_list.unshift(phi)

          # only add each block to this name's work list once
          if not processed.include?(d)
            work_list = work_list | [d]
            processed = processed | [d]
          end
        }
      }
    }
  end

  sig { params(block: BB, name: String).returns(T.nilable(IL::Phi)) }
  def find_phi(block, name)
    # scan block statements in order for matching phi
    block.stmt_list.each { |s|
      # blocks often start with a label, skip this
      if s.is_a?(IL::Label)
        next
      end

      # phi functions are Definitions with an rhs of type Phi
      # since phi functions must appear all at the beginning of the block,
      # as soon as we see a statement that doesn't match this we can stop
      # the check
      if (not s.is_a?(IL::Definition)) or (not s.rhs.is_a?(IL::Phi))
        break
      end

      # check if phi function applies to correct id
      if s.id.name == name
        return T.cast(s.rhs, IL::Phi)
      end
    }

    return nil
  end

  sig { void }
  def find_globals
    @globals.clear
    @blocks.clear # block sets will be created as we go

    # for each block b
    @cfg.each_node { |b|
      var_kill = T.let(Set[], T::Set[String])
      # for each statement in b
      b.stmt_list.each { |s|
        case s
        when IL::Definition
          # add names on rhs to globals
          names = get_rhs_names(s.rhs)
          names.each { |n|
            if not var_kill.include?(n)
              @globals.add(n)
            end
          }

          # add lhs to var_kill
          var_kill.add(s.id.name)

          # note the type of the lhs
          @global_types[s.id.name] = s.type

          # add this block to lhs's blocks set
          if not @blocks[s.id.name]
            @blocks[s.id.name] = Set[b]
          else
            T.unsafe(@blocks[s.id.name]).add(b)
          end
        when IL::JumpZero
          # add conditional name to globals
          names = get_rhs_names(s.cond)
          names.each { |n| # there will only ever be one but whatever
            if not var_kill.include?(n)
              @globals.add(n)
            end
          }
        when IL::JumpNotZero
          # add conditional name to globals
          names = get_rhs_names(s.cond)
          names.each { |n| # there will only ever be one but whatever
            if not var_kill.include?(n)
              @globals.add(n)
            end
          }
        when IL::Return
          # add names on rhs to globals
          names = get_rhs_names(s.value)
          names.each { |n|
            if not var_kill.include?(n)
              @globals.add(n)
            end
          }
        end
      }
    }
  end

  sig { params(rhs: T.any(IL::Value, IL::Expression))
          .returns(T::Set[String]) }
  def get_rhs_names(rhs)
    case rhs
    when IL::Constant then return Set[]
    when IL::ID then return Set[rhs.name]
    when IL::BinaryOp
      return get_rhs_names(rhs.left) | get_rhs_names(rhs.right)
    when IL::UnaryOp then return get_rhs_names(rhs.value)
    when IL::Call
      names = T.let(Set[], T::Set[String])
      rhs.args.each { |a|
        names = names | get_rhs_names(a)
      }
      return names
    # NOTE: Phi intentionally not supported here
    #   no Phi functions should exist in the IL when this runs
    else
      raise("Unsupported rhs: #{rhs.class}")
    end
  end

  sig { params(dom_tree: DomTree).void }
  def rename_globals(dom_tree)
    counter = Hash.new
    stack = Hash.new

    # initialize set for each id
    @globals.each { |name|
      counter[name] = 0
      stack[name] = []
    }

    # begin on root of dom tree (a.k.a. CFG entry)
    rename(@cfg.entry, counter, stack, dom_tree)
  end

  sig { params(name: String,
               counter: T::Hash[String, Integer],
               stack: T::Hash[String, T::Array[Integer]])
          .returns(IL::ID) }
  def new_name(name, counter, stack)
    # unsafes should never break
    i = T.unsafe(counter[name])
    if not i
      # TODO: I think this issue is resolved now but its untested
      # puts("WARN: i for #{name} was nil")
      i = 0
      stack[name] = [] # will be needed later
    end
    counter[name] = i + 1
    T.unsafe(stack[name]).push(i)

    return IL::ID.new(name, number: i)
  end

  sig { params(block: BB,
               counter: T::Hash[String, Integer],
               stack: T::Hash[String, T::Array[Integer]],
               dom_tree: DomTree).void }
  def rename(block, counter, stack, dom_tree)
    # for each phi function in block, rewrite lhs with new_name
    block.stmt_list.each { |s|
      if (not s.is_a?(IL::Definition)) or (not s.rhs.is_a?(IL::Phi))
        break
      end

      # rewrite lhs with new_name
      s.id = new_name(s.id.name, counter, stack)
    }

    # for each definition in block
    block.stmt_list.each { |s|
      # skip past Phi definitions since those were handled above
      if (not s.is_a?(IL::Definition)) or s.rhs.is_a?(IL::Phi)
        next
      end

      # rewrite rhs expression using stack
      rewrite_rhs(s.rhs, counter, stack)

      # rewrite lhs of definition with new_name
      s.id = new_name(s.id.name, counter, stack)
    }

    # for each successor of block in the *CFG*
    @cfg.each_successor(block) { |s|
      # fill in phi function arguments
      stack.keys.each { |name|
        # see if there is a phi for this name in the successor
        phi = find_phi(s, name)
        if not phi
          next
        end

        # if there is a phi for it, add the current subscript to the phi
        number = T.unsafe(stack[name])[-1]
        if not number # TODO: unsure how this can happen but it does
          # puts("WARN: no number found for name being pushed to phi")
          next
        end

        phi.ids.push(IL::ID.new(name, number: number))
      }
    }

    # call rename on each successor of block in the *dom tree*
    dom_tree.each_successor(block) { |s|
      rename(s, counter, stack, dom_tree)
    }

    # for each definition (and each phi function, which are always definitions
    # in this IL), pop stack[lhs]
    block.stmt_list.each { |s|
      if not s.is_a?(IL::Definition)
        next
      end

      T.unsafe(stack[s.id.name]).pop()
    }
  end

  sig { params(rhs: T.any(IL::Expression, IL::Value),
               counter: T::Hash[String, Integer],
               stack: T::Hash[String, T::Array[Integer]]).void }
  def rewrite_rhs(rhs, counter, stack)
    case rhs
    # Constants have nothing to rewrite
    when IL::Constant then return
    # Phis will be handled somewhere else
    when IL::Phi then return
    when IL::ID
      # rewrite id with top of stack[name]
      rhs.number = T.unsafe(T.unsafe(stack[rhs.name])[-1])
    when IL::BinaryOp
      # recurse on operands
      rewrite_rhs(rhs.left, counter, stack)
      rewrite_rhs(rhs.right, counter, stack)
    when IL::UnaryOp
      # recurse on operand
      rewrite_rhs(rhs.value, counter, stack)
    when IL::Call
      # recurse on all args
      rhs.args.each { |a|
        rewrite_rhs(a, counter, stack)
      }
    else
      raise("Attempted to rewrite unrecognized rhs: #{rhs.class}")
    end
  end
end
