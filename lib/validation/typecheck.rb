# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation_pass"
require_relative "../il"
require_relative "../symbol_table"

module Lilac
  module Validation
    # The type-check validation ensures that there are no definitions or
    # expressions with mismatched types in the program.
    class TypeCheck < ValidationPass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "typecheck"
      end

      sig { override.returns(String) }
      def self.description
        "Detect type mismatches in definitions and expressions"
      end

      sig { params(program: IL::Program).void }
      def initialize(program)
        @program = program
      end

      sig { override.void }
      def run!
        symbols = SymbolTable.new
        funcs = {} # name -> return type

        # scan all globals
        symbols.push_scope # top level scope
        @program.each_global do |g|
          symbols.insert(ILSymbol.new(g.id, g.type))
        end

        # store function return types
        @program.each_func do |f|
          funcs[f.name] = f.ret_type
        end

        # scan on all functions
        @program.each_func do |f|
          scan_items(f.stmt_list, symbols, funcs)
        end
        symbols.pop_scope
      end

      private

      sig do
        params(items: T::Array[IL::Statement],
               symbols: SymbolTable,
               funcs: T::Hash[String, String]).void
      end
      def scan_items(items, symbols, funcs)
        items.each do |i|
          # only definitions are relevant
          unless i.is_a?(IL::Definition)
            next
          end

          # register id in symbol table for every def (since this is SSA)
          symbols.insert(ILSymbol.new(i.id, i.type))

          # find the type of the rhs
          case i.rhs
          when IL::Constant
            rhs_type = T.cast(i.rhs, IL::Constant).type
          when IL::ID
            rhs_symbol = symbols.lookup(T.cast(i.rhs, IL::ID))
            unless rhs_symbol
              raise("Symbol not found: #{T.cast(i.rhs, IL::ID)}")
            end

            rhs_type = rhs_symbol.type
          when IL::Call
            rhs_type = funcs[T.cast(i.rhs, IL::Call).func_name]
          when IL::Expression
            rhs_type = get_expr_type(T.cast(i.rhs, IL::Expression), symbols)
          end

          # check for a mismatch
          unless rhs_type
            raise("Expression has nil type: '#{i.rhs}'")
          end

          id_symbol = symbols.lookup(i.id)
          unless id_symbol
            raise("Symbol not found: #{i.id}")
          end
          if id_symbol.type != rhs_type
            raise("Type mismatch in statement: '#{i}'")
          end
        end
      end

      sig do
        params(expr: IL::Expression,
               symbols: SymbolTable)
          .returns(T.nilable(IL::Types::Type))
      end
      def get_expr_type(expr, symbols)
        if expr.is_a?(IL::BinaryOp)
          # get type of left
          if expr.left.is_a?(IL::Constant)
            lconst = T.cast(expr.left, IL::Constant)
            ltype = lconst.type
          elsif expr.left.is_a?(IL::ID)
            lid = T.cast(expr.left, IL::ID)
            lsymbol = symbols.lookup(lid)
            unless lsymbol
              raise("Symbol not found: #{lid}")
            end

            ltype = lsymbol.type
          else
            raise("Unsupported left value class: #{expr.left.class}")
          end

          # get type of right
          if expr.right.is_a?(IL::Constant)
            rconst = T.cast(expr.right, IL::Constant)
            rtype = rconst.type
          elsif expr.right.is_a?(IL::ID)
            rid = T.cast(expr.right, IL::ID)
            rsymbol = symbols.lookup(rid)
            unless rsymbol
              raise("Symbol not found: #{rid}")
            end

            rtype = rsymbol.type
          else
            raise("Unsupported right value class: #{expr.right.class}")
          end

          # return if they match, otherwise nil
          if ltype == rtype then return ltype end

          return nil
        elsif expr.is_a?(IL::UnaryOp)
          # get type of value
          if expr.value.is_a?(IL::Constant)
            vconst = T.cast(expr.value, IL::Constant)
            vtype = vconst.type
          elsif expr.value.is_a?(IL::ID)
            vid = T.cast(expr.value, IL::ID)
            vsymbol = symbols.lookup(vid)
            unless vsymbol
              raise("Symbol not found: #{vid}")
            end

            vtype = vsymbol.type
          else
            raise("Unsupported value class: #{expr.value.class}")
          end

          return vtype # no need to check for mismatch
        end

        raise("Unsupported expression class: #{expr.class}")
      end
    end
  end
end
