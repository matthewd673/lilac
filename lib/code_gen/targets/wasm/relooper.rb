# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "wasm"
require_relative "wasm_block"
require_relative "../../../analysis/bb"
require_relative "../../../analysis/cfg"
require_relative "../../../analysis/dom_tree"
require_relative "../../../analysis/reducible"

module CodeGen
  module Targets
    module Wasm
      # The Relooper class converts a CFGProgram with aribrary gotos into a
      # structured control flow form. It is not based on the relooper algorithm
      # presented in the original Emscripten paper but rather on the algorithm
      # described in the "Beyond Relooper" paper:
      #   Norman Ramsey. 2022. Beyond Relooper: recursive translation of
      #     unstructured control flow to structured control flow
      #     (functional pearl). Proc. ACM Program. Lang. 6, ICFP, Article 90
      #     (August 2022), 22 pages. https://doi.org/10.1145/3547621
      class Relooper
        extend T::Sig

        include CodeGen::Targets::Wasm

        sig { params(cfg: Analysis::CFG, dom_tree: Analysis::DomTree).void }
        # Initialize a new Relooper.
        #
        # @param [Analysis::CFG] cfg The CFG to run the Relooper algorithm on.
        # @param [Analysis::DomTree] dom_tree The dominance tree for the given
        #   CFG.
        def initialize(cfg, dom_tree)
          @cfg = cfg
          @dom_tree = dom_tree

          reducible = Analysis::Reducible.new(cfg).run
          # TODO: convert to reducible if it isn't already
          unless reducible
            raise "CFG is not reducible"
          end

          # to be filled in later
          @props = T.let({}, T::Hash[Analysis::BB, T::Set[BlockProperty]])

          # compute RPO
          @cfg_rpo = T.let(@cfg.reverse_postorder_numbering(@cfg.entry),
                           T::Hash[Analysis::BB, Integer])
        end

        sig { returns(WasmBlock) }
        # Translate the provided CFG into a nested set of structured control
        # flow blocks.
        #
        # @return [WasmBlock] The root structured control flow block.
        def translate
          # classify each node in the CFG
          classify_nodes

          # translate everything starting at entry
          do_tree(@cfg.entry)
        end

        private

        # A BlockProperty is a structured control flow property that a basic
        # block can have.
        class BlockProperty < T::Enum
          enums do
            If = new
            Join = new
            Loop = new # LoopHeader
          end
        end

        sig { void }
        def classify_nodes
          @cfg.each_node do |b|
            b_props = Set.new

            # "a node that has two or more forward inedges is a merge node"
            # (join)
            forward_inedges = 0
            @cfg.each_incoming(b) do |e|
              if forward_edge?(e)
                forward_inedges += 1
              end
            end

            if forward_inedges >= 2 # is a join node
              b_props.add(BlockProperty::Join)
            end

            # "a node that ends in a conditional branch has two outedges and is
            #   translated into an if form"
            if @cfg.outgoing_length(b) >= 2 # TODO: >= or strictly equal?
              b_props.add(BlockProperty::If)
            end

            # "a node that has a back inedge is a loop header, and its
            # translation is wrapped in a loop form"
            has_back_inedge = T.let(false, T::Boolean)
            @cfg.each_incoming(b) do |e|
              if back_edge?(e)
                has_back_inedge = true
                break
              end
            end

            if has_back_inedge
              b_props.add(BlockProperty::Loop)
            end

            @props[b] = b_props
          end
        end

        sig { params(edge: Graph::Edge[Analysis::BB]).returns(T::Boolean) }
        def forward_edge?(edge)
          from = @cfg_rpo[edge.from]
          to = @cfg_rpo[edge.to]

          if !from || !to
            raise "Invalid edge from #{edge.from} to #{edge.to}"
          end

          from < to
        end

        sig { params(edge: Graph::Edge[Analysis::BB]).returns(T::Boolean) }
        def back_edge?(edge)
          from = @cfg_rpo[edge.from]
          to = @cfg_rpo[edge.to]

          if !from || !to
            raise "Invalid edge from #{from} to #{to}"
          end

          # self-loops are back edges
          from >= to
        end

        sig { params(node: Analysis::BB).returns(WasmBlock) }
        # Recursively translate all nodes immediately dominated by the given
        # node.
        def do_tree(node)
          # children are sorted by rpo numbering
          children = []
          @dom_tree.each_successor(node) { |s| children.push(s) }
          children.sort_by { |c| T.unsafe(@cfg_rpo[c]) }

          # create a new wasm block for this node
          wasm_block = if T.unsafe(@props[node]).include?(BlockProperty::Loop)
                         WasmLoopBlock.new(node)
                       elsif T.unsafe(@props[node]).include?(BlockProperty::If)
                         WasmIfBlock.new(node)
                       else
                         WasmBlock.new(node)
                       end

          last_block = wasm_block # used to chain children in next_block

          children.each do |c|
            translation = do_tree(c)

            # place child in a conditional wasm block
            # join
            # TODO: what if a node dominates multiple join nodes? see page 6
            # (90:6)
            if wasm_block.is_a?(WasmIfBlock) &&
               T.unsafe(@props[c]).include?(BlockProperty::Join)

              last_block.next_block = translation
              last_block = translation
            # true
            elsif wasm_block.is_a?(WasmIfBlock) && c.true_branch
              wasm_block.true_branch = translation
            # false
            elsif wasm_block.is_a?(WasmIfBlock) && !c.true_branch
              wasm_block.false_branch = translation

            # place child in a loop header wasm block
            elsif wasm_block.is_a?(WasmLoopBlock)
              # NOTE: this is not derived from the original paper and may
              # produce incorrect behavior

              # if child dominates a node that has a backedge to node
              # then place child in WasmLoopBlock.inner
              # otherwise, the child is the next_block of the loop
              is_inner = T.let(false, T::Boolean)
              @dom_tree.dom_by(c) do |d|
                @cfg.each_outgoing(d) do |o|
                  if o.to == node && back_edge?(o)
                    is_inner = true
                    break
                  end
                end

                if is_inner then break end
              end

              if is_inner
                wasm_block.inner = translation
              else
                wasm_block.next_block = translation
                last_block = translation
              end
            # place child normally
            else
              last_block.next_block = translation
              last_block = translation
            end
          end

          wasm_block
        end

        # TODO: move these within the debugger namespace
        sig { params(block: T.nilable(WasmBlock), depth: Integer).void }
        def print_wasm_block(block, depth)
          tab = ""
          (0..depth).each do |_|
            tab += "  "
          end
          unless block
            puts("#{tab}  next_block: nil")
            return
          end

          case block
          when WasmIfBlock
            puts("#{tab}WasmIfBlock:")

            puts("#{tab}  bb: #{block.bb}")

            puts("#{tab}  true_branch:")
            print_wasm_block(block.true_branch, depth + 2)
            puts("#{tab}  false_branch:")
            print_wasm_block(block.false_branch, depth + 2)

            print_wasm_block(block.next_block, depth)
          when WasmLoopBlock
            puts("#{tab}WasmLoopBlock:")

            puts("#{tab}  bb: #{block.bb}")

            puts("#{tab}  inner:")
            print_wasm_block(block.inner, depth + 2)

            print_wasm_block(block.next_block, depth)
          when WasmBlock
            puts("#{tab}WasmBlock:")

            puts("#{tab}  bb: #{block.bb}")

            print_wasm_block(block.next_block, depth)
          end
        end
      end
    end
  end
end
