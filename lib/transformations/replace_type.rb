# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../pass"
require_relative "../il"
require_relative "../il_walker"

module Lilac
  module Transformations
    # The ReplaceType pass replaces all occurrences of a given type in an
    # IL Program with another type. NOTE: This transformation will
    # nearly-always change the behavior of the IL Program.
    class ReplaceType < Pass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "replace_type"
      end

      sig { override.returns(String) }
      def self.description
        "Replace a given type in an IL Program with a different type (unsafe)"
      end

      sig do
        params(program: IL::Program,
               type_map: T::Hash[IL::Type::Type, IL::Type::Type])
          .void
      end
      # Construct a new ReplaceType transformation.
      #
      # @param [IL::Program] program The Program to run the transformation on.
      # @param [T::Hash[IL::Type, IL::Type]] type_map The map of type
      #   replacements to be performed. Key is the type to replace, value is
      #   its replacement.
      def initialize(program, type_map)
        @program = program
        @type_map = type_map

        walk_lambda = lambda do |o|
          case o
          when IL::Constant, IL::Definition, IL::FuncParam
            # replace type
            if @type_map.include?(o.type)
              o.type = T.unsafe(@type_map[o.type])
            end
          when IL::FuncDef
            # replace return type
            if @type_map.include?(o.ret_type)
              o.ret_type = T.unsafe(@type_map[o.ret_type])
            end
          when IL::ExternFuncDef
            # replace return type
            if @type_map.include?(o.ret_type)
              o.ret_type = T.unsafe(@type_map[o.ret_type])
            end
            # replace all param types
            o.param_types.map do |t|
              @type_map.include?(t) ? T.unsafe(@type_map[t]) : t
            end
          end
        end.freeze

        @walker = T.let(ILWalker.new(walk_lambda), ILWalker)
      end

      sig { override.void }
      def run!
        @walker.walk(@program)
      end
    end
  end
end
