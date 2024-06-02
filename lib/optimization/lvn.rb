# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization_pass"
require_relative "../analysis/bb"

module Lilac
  module Optimization
    # The LVN optimization performs local value numbering.
    class LVN < OptimizationPass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "lvn"
      end

      sig { override.returns(String) }
      def self.description
        "Local value numbering"
      end

      sig { override.returns(Integer) }
      def self.level
        1
      end

      sig { override.returns(UnitType) }
      def self.unit_type
        UnitType::BasicBlock
      end

      sig { params(block: Analysis::BB).void }
      def initialize(block)
        @block = block
        @value_number_map = T.let(ValueNumberMap.new, ValueNumberMap)
        @id_number_map = T.let(IDNumberMap.new, IDNumberMap)
      end

      sig { override.void }
      def run!
        @block.stmt_list.each do |s|
          # perform constant folding on conditional jump conditions
          # this is a bonus on top of LVN's core task
          if s.is_a?(IL::JumpZero) || s.is_a?(IL::JumpNotZero)
            cond = constant_folding(s.cond)
            # swap out cond only if the new result is a constant
            if cond.is_a?(IL::Constant)
              s.cond = cond
            end
            next # job's done with the jmps
          end

          # only definitions are relevant
          unless s.is_a?(IL::Definition)
            next
          end

          # try to precompute rhs (constant-folding)
          rhs = constant_folding(s.rhs)

          # don't perform any type of lvn on function calls -- just skip
          # NOTE: if a function has no side-effects, lvn could work...
          if rhs.is_a?(IL::Call)
            next
          end

          # get or insert the value (existing shows if it existed before or not)
          number = @value_number_map.get_number_by_value(rhs)
          existing = true
          unless number
            number = @value_number_map.insert_value(rhs)
            existing = false
          end

          # associate number with the id being assigned to
          @id_number_map.assign_id(s.id, number)

          # constants on the rhs are always better off staying as constants
          if rhs.is_a?(IL::Constant)
            s.rhs = rhs
            s.annotation = "#{number} (is constant)" if existing
            next
          end

          # brand new values will never have their rhs replaced
          unless existing
            next
          end

          # if the value exists in another id, set rhs to that id
          existing_id = @id_number_map.get_id_by_number(number)
          if existing_id
            s.rhs = existing_id
            s.annotation = number.to_s # TODO: temp
            next
          end

          existing_hash = @value_number_map.get_value_by_number(number)
          next unless existing_hash

          s.rhs = existing_hash
          s.annotation = number.to_s # TODO: temp
          next
        end
      end

      private

      sig do
        params(rhs: T.any(IL::Expression, IL::Value))
          .returns(T.any(IL::Expression, IL::Value))
      end
      def constant_folding(rhs)
        case rhs
        when IL::Constant # nothing to do
        when IL::ID
          # check if the id has a value number
          id_number = @id_number_map.get_number_by_id(rhs)
          unless id_number then return rhs end

          # id has a value number so get its value, recurse, and return that
          val = T.unsafe(@value_number_map.get_value_by_number(id_number))
          return constant_folding(val) # recurse on that value and return
        when IL::BinaryOp
          # recurse on left and right (in case they are ids mapped to constants)
          left = constant_folding(rhs.left)
          right = constant_folding(rhs.right)

          # calculate if both sides are constants
          if left.is_a?(IL::Constant) && right.is_a?(IL::Constant)
            calc_binop = IL::BinaryOp.new(rhs.op, left, right)

            # TODO: below calculation ignores type mismatch
            constant_result = IL::Constant.new(left.type, calc_binop.calculate)
            return constant_result
          end

          # otherwise, return a binop with left and right folded
          if left.is_a?(IL::Value) && right.is_a?(IL::Value)
            return IL::BinaryOp.new(rhs.op, left, right)
          end

          # if they aren't values, theres nothing we can do
        when IL::UnaryOp
          # recurse on value (in case they are ids mapped to constants)
          value = T.cast(constant_folding(rhs.value), IL::Value)

          # calculate if both sides are constants
          if value.is_a?(IL::Constant)
            calc_unop = IL::UnaryOp.new(rhs.op, value)
            constant_result = IL::Constant.new(value.type, calc_unop.calculate)
            return constant_result
          end

          # otherwise, return a unop with value folded
          return IL::UnaryOp.new(rhs.op, value)
        when IL::Call # TODO
        else
          raise "rhs type #{rhs.class} not supported by constant_folding"
        end

        rhs
      end

      # The ValueNumberMap class stores mappings of values and their local
      # numbers.
      class ValueNumberMap
        extend T::Sig

        sig { void }
        def initialize
          @index_to_value = T.let([],
                                  T::Array[T.any(IL::Expression, IL::Value)])
          @value_to_index = T.let({},
                                  T::Hash[T.any(IL::Expression, IL::Value),
                                          Integer])
        end

        sig { params(value: T.any(IL::Expression, IL::Value)).returns(Integer) }
        def insert_value(value)
          @index_to_value.push(value)
          number = @index_to_value.length - 1
          @value_to_index[value] = number

          # insert this new value number into the value_to_index hash
          # so if this value number exactly appears on a right-hand-side
          # it will be easy to find
          @value_to_index[ValueNumber.new(number)] = number

          number
        end

        sig do
          params(number: Integer)
            .returns(T.nilable(T.any(IL::Expression, IL::Value)))
        end
        def get_value_by_number(number)
          @index_to_value[number]
        end

        sig do
          params(value: T.any(IL::Expression, IL::Value))
            .returns(T.nilable(Integer))
        end
        def get_number_by_value(value)
          @value_to_index[value]
        end
      end
      private_constant :ValueNumberMap

      # The IDNumberMap class stores mappings of IDs and their local numbers.
      class IDNumberMap
        extend T::Sig

        sig { void }
        def initialize
          @id_to_number = T.let({}, T::Hash[IL::ID, Integer])
          @number_to_ids = T.let({}, T::Hash[Integer, T::Array[IL::ID]])
        end

        sig { params(id: IL::ID, number: Integer).void }
        def assign_id(id, number)
          old_number = @id_to_number[id]
          if old_number
            old_id_list = @number_to_ids[old_number]
            # will always be true, check for sorbet's sake
            old_id_list&.delete(id)
          end

          @id_to_number[id] = number

          id_list = @number_to_ids[number]
          if id_list
            id_list.push(id)
          else
            @number_to_ids[number] = [id]
          end
        end

        sig { params(id: IL::ID).returns(T.nilable(Integer)) }
        def get_number_by_id(id)
          @id_to_number[id]
        end

        sig { params(number: Integer).returns(T.nilable(IL::ID)) }
        def get_id_by_number(number)
          id_list = @number_to_ids[number]

          unless id_list
            return nil
          end

          id_list[0]
        end
      end
      private_constant :IDNumberMap

      # A ValueNumber is a special +IL::Value+ that represents a local value
      # number.
      class ValueNumber < IL::Value
        extend T::Sig

        sig { returns(Integer) }
        attr_reader :number

        sig { params(number: Integer).void }
        def initialize(number)
          @number = number
        end

        sig { override.returns(String) }
        def to_s
          "##{@number}"
        end

        sig { returns(Integer) }
        def hash
          [self.class, @number].hash
        end
      end
      private_constant :ValueNumber
    end
  end
end
