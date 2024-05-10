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
      extend T::Generic

      Unit = type_member { { fixed: Analysis::BB } }

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

      sig { params(block: Unit).void }
      def initialize(block)
        @block = block
      end

      sig { override.void }
      def run!
        value_number_map = ValueNumberMap.new
        id_number_map = IDNumberMap.new

        @block.stmt_list.each do |s|
          # perform constant folding on conditional jump conditions
          # this is a bonus on top of LVN's core task
          if s.is_a?(IL::JumpZero) || s.is_a?(IL::JumpNotZero)
            cond = constant_folding(s.cond, value_number_map, id_number_map)
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
          rhs = constant_folding(s.rhs, value_number_map, id_number_map)

          # don't perform any type of lvn on function calls -- just skip
          # NOTE: if a function has no side-effects, lvn could work...
          if rhs.is_a?(IL::Call)
            next
          end

          # calculate hash for rhs
          rhs_val = ValueHash.new(rhs, value_number_map, id_number_map)
          # get or insert the value (existing shows if it existed before or not)
          number = value_number_map.get_number_by_value(rhs_val.hash)
          existing = true
          unless number
            number = value_number_map.insert_value(rhs_val)
            existing = false
          end

          # associate number with the id being assigned to
          id_number_map.assign_id(s.id, number)

          # constants on the rhs are always better off staying as constants
          if rhs_val.value.is_a?(IL::Constant)
            s.rhs = rhs_val.value
            s.annotation = "#{number} (is constant)" if existing
            next
          end

          # brand new values will never have their rhs replaced
          unless existing
            next
          end

          # if the value exists in another id, set rhs to that id
          existing_id = id_number_map.get_id_by_number(number)
          if existing_id
            s.rhs = existing_id
            s.annotation = number.to_s # TODO: temp
            next
          end

          existing_hash = value_number_map.get_value_by_number(number)
          next unless existing_hash

          s.rhs = existing_hash.value
          s.annotation = number.to_s # TODO: temp
          next
        end
      end

      private

      sig do
        params(rhs: T.any(IL::Expression, IL::Value),
               value_number_map: ValueNumberMap,
               id_number_map: IDNumberMap)
          .returns(T.any(IL::Expression, IL::Value))
      end
      def constant_folding(rhs, value_number_map, id_number_map)
        case rhs
        when IL::ID
          # check if the id has a value number
          id_number = id_number_map.get_number_by_id(rhs)

          # if it has a value number, get it and check if its a constant
          unless id_number then return rhs end

          id_value = value_number_map.get_value_by_number(id_number)

          unless id_value then return rhs end # will never happen

          # if its a constant, set rhs to that constant
          if id_value.value.is_a?(IL::Constant)
            return id_value.value
          end
        when IL::BinaryOp
          # recurse on left and right (in case they are ids mapped to constants)
          left = constant_folding(rhs.left, value_number_map, id_number_map)
          right = constant_folding(rhs.right, value_number_map, id_number_map)

          # only calculate if both sides are constants
          if left.is_a?(IL::Constant) && right.is_a?(IL::Constant)
            rhs.left = left
            rhs.right = right
            # TODO: below calculation ignores type mismatch
            constant_result = IL::Constant.new(left.type, rhs.calculate)
            return constant_result
          end
        when IL::UnaryOp
          # recurse on value (in case they are ids mapped to constants)
          value = constant_folding(rhs.value, value_number_map, id_number_map)

          # only calculate if both sides are constants
          if value.is_a?(IL::Constant)
            rhs.value = value
            constant_result = IL::Constant.new(value.type, rhs.calculate)
            return constant_result
          end
        end

        rhs
      end

      # The ValueNumberMap class stores mappings of values and their local
      # numbers.
      class ValueNumberMap
        extend T::Sig

        sig { void }
        def initialize
          @index_to_value = T.let([], T::Array[ValueHash])
          @value_to_index = T.let({}, T::Hash[String, Integer])
        end

        sig { params(value: ValueHash).returns(Integer) }
        def insert_value(value)
          @index_to_value.push(value)
          number = @index_to_value.length - 1
          @value_to_index[value.hash] = number

          # insert this new value number into the value_to_index hash
          # so if this value number exactly appears on a right-hand-side
          # it will be easy to find
          @value_to_index[number.to_s] = number

          number
        end

        sig { params(number: Integer).returns(T.nilable(ValueHash)) }
        def get_value_by_number(number)
          @index_to_value[number]
        end

        sig { params(value: String).returns(T.nilable(Integer)) }
        def get_number_by_value(value)
          @value_to_index[value]
        end
      end

      # The IDNumberMap class stores mappings of IDs and their local numbers.
      class IDNumberMap
        extend T::Sig

        sig { void }
        def initialize
          @id_to_number = T.let({}, T::Hash[String, Integer]) # id.key -> number
          @number_to_ids = T.let({}, T::Hash[Integer, T::Array[IL::ID]])
        end

        sig { params(id: IL::ID, number: Integer).void }
        def assign_id(id, number)
          old_number = @id_to_number[id.key]
          if old_number
            old_id_list = @number_to_ids[old_number]
            # will always be true, check for sorbet's sake
            old_id_list&.delete(id)
          end

          @id_to_number[id.key] = number

          id_list = @number_to_ids[number]
          if id_list
            id_list.push(id)
          else
            @number_to_ids[number] = [id]
          end
        end

        sig { params(id: IL::ID).returns(T.nilable(Integer)) }
        def get_number_by_id(id)
          @id_to_number[id.key]
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

      # The ValueHash class creates hash values for values that can be used
      # to index them.
      class ValueHash
        extend T::Sig

        sig { returns(HashType) }
        attr_reader :value

        sig { returns(String) }
        attr_reader :hash

        sig do
          params(value: HashType,
                 value_number_map: ValueNumberMap,
                 id_number_map: IDNumberMap).void
        end
        def initialize(value, value_number_map, id_number_map)
          @value = value

          @value_number_map = value_number_map
          @id_number_map = id_number_map

          @hash = T.let(compute_hash(value), String)
        end

        private

        HashType = T.type_alias do
          T.any(ValueNumber,
                IL::Value,
                IL::Expression)
        end

        sig { params(value: HashType).returns(String) }
        def compute_hash(value)
          case value
          when ValueNumber
            value.number.to_s
          when IL::Constant
            "#{value.type}:#{value.value}"
          when IL::ID
            # lookup value number for id
            # (if id is defined in another block it may not exist)
            number = @id_number_map.get_number_by_id(value)
            number ||= -1
            number.to_s
          when IL::BinaryOp
            left_hash = compute_hash(value.left)
            right_hash = compute_hash(value.right)
            "(#{value.op} #{left_hash} #{right_hash})"
          when IL::UnaryOp
            "(#{value.op} #{compute_hash(value.value)})"
          else
            raise("Unsupported value type in hash function: #{value.class}")
          end
        end
      end

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
      end
    end
  end
end
