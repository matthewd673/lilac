# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation_pass"
require_relative "../il"

module Lilac
  module Validation
    # The ID Naming validation ensures that ID names do not include
    # reserved characters. It is very possible for ID names with reserved
    # characters to compile fine, but it is introduces unnecessary
    # ambiguity.
    class IDNaming < ValidationPass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "id_naming"
      end

      sig { override.returns(String) }
      def self.description
        "Ensure that ID names do not include reserved characters"
      end

      sig { params(program: IL::Program).void }
      def initialize(program)
        @program = program
      end

      sig { override.void }
      def run!
        # scan all funcs
        @program.each_func do |f|
          # scan params
          f.params.each do |p|
            # skip registers, which are named automatically
            if p.id.is_a?(IL::Register) then next end

            unless valid?(p.id.name)
              raise("Reserved character in ID name '#{p.id.name}'")
            end
          end

          # check function name
          # (this won't check Calls but you must def a func to call it so...)
          unless valid?(f.name)
            raise("Reserved character in FuncDef name '#{f.name}'")
          end

          # scan contents of function
          scan_items(f.stmt_list)
        end

        # scan program
        scan_items(@program.stmt_list)
      end

      private

      sig { params(stmt_list: T::Array[IL::Statement]).void }
      def scan_items(stmt_list)
        stmt_list.each do |s|
          # only defs are relevant
          # (every id must be defined, another validation will check that)
          unless s.is_a?(IL::Definition)
            next
          end

          # skip registers
          if s.id.is_a?(IL::Register)
            next
          end

          unless valid?(s.id.name)
            raise("Reserved character in ID name '#{s.id.name}'")
          end
        end
      end

      sig { params(name: String).returns(T::Boolean) }
      def valid?(name)
        !(name.empty? or name.include?("%") or name.include?("#"))
      end

      sig do
        params(node: T.any(IL::FuncDef,
                           IL::Statement,
                           IL::Expression,
                           IL::Value))
          .returns(T::Array[IL::ID])
      end
      def get_ids(node)
        case node
        when IL::Definition
          return [node.id].concat(get_ids(node.rhs))
        when IL::JumpZero
          return get_ids(node.cond)
        when IL::JumpNotZero
          return get_ids(node.cond)
        when IL::BinaryOp
          return get_ids(node.left).concat(get_ids(node.right))
        when IL::UnaryOp
          return get_ids(node.value)
        when IL::ID
          return [node]
        end

        []
      end
    end
  end
end
