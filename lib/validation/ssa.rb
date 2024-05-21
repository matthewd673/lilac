# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation_pass"
require_relative "../il"

module Lilac
  module Validation
    # The SSA validation ensures that the program is in valid SSA form.
    class SSA < ValidationPass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "ssa"
      end

      sig { override.returns(String) }
      def self.description
        "Ensure the program is in valid SSA form"
      end

      sig { params(program: IL::Program).void }
      def initialize(program)
        @program = program
      end

      sig { override.void }
      def run!
        symbols = SymbolTable.new
        symbols.push_scope # top level scope

        # scan top level of program
        scan_stmt_list(@program.stmt_list, symbols)

        # scan all funcs
        @program.each_func do |f|
          # create a new scope (NOTE: assumes ssa doesn't hold between funcs)
          symbols.push_scope

          # scan and register params
          f.params.each do |p|
            if symbols.lookup(p.id)
              raise "Multiple definitions of ID '#{p.id}'"
            end

            symbols.insert(ILSymbol.new(p.id, p.type))
          end

          # recursive scan
          scan_stmt_list(f.stmt_list, symbols)
          symbols.pop_scope
        end
      end

      private

      sig do
        params(stmt_list: T::Array[IL::Statement], symbols: SymbolTable).void
      end
      def scan_stmt_list(stmt_list, symbols)
        stmt_list.each do |s|
          # only definitions are relevant
          unless s.is_a?(IL::Definition)
            next
          end

          if symbols.lookup(s.id)
            raise("Multiple definitions of ID '#{s.id}'")
          end

          symbols.insert(ILSymbol.new(s.id, s.type))
        end
      end
    end
  end
end
