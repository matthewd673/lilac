# typed: strict
require "sorbet-runtime"
require_relative "optimization"

class LVN < Optimization
  extend T::Sig

  sig { void }
  def initialize
    @id = T.let("lvn", String)
    @full_name = T.let("local value numbering", String)
    @level = T.let(1, Integer)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    block_list = BB.create_blocks(program)
    block_list.each { |b|

      value_number_map = ValueNumberMap.new
      id_number_map = IDNumberMap.new

      b.each_stmt { |s|
        # only declarations and assignments are relevant
        if not (s.is_a?(IL::Declaration) or s.is_a?(IL::Assignment))
          next
        end

        # calculate hash for rhs
        rhs_val = ValueHash.new(s.rhs, value_number_map, id_number_map)
        # get or insert the value (existing shows if it existed before or not)
        number = value_number_map.get_number_by_value(rhs_val.hash)
        existing = true
        if not number
          number = value_number_map.insert_value(rhs_val)
          existing = false
        end

        # associate number with the id being assigned to
        id_number_map.assign_id(s.id.name, number)

        if not existing
          next
        end

        existing_id = id_number_map.get_id_by_number(number)
        if existing_id
          s.rhs = IL::ID.new(existing_id)
          s.annotation = number.to_s # TODO: temp
          next
        end

        existing_hash = value_number_map.get_value_by_number(number)
        if existing_hash
          s.rhs = existing_hash.value
          s.annotation = number.to_s # TODO: temp
          next
        end
      }
    }
  end

  private

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

      return number
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

  class IDNumberMap
    extend T::Sig

    sig { void }
    def initialize
      @id_to_number = T.let({}, T::Hash[String, Integer])
      @number_to_ids = T.let({}, T::Hash[Integer, T::Array[String]])
    end

    sig { params(id: String, number: Integer).void }
    def assign_id(id, number)
      old_number = @id_to_number[id]
      if old_number
        old_id_list = @number_to_ids[old_number]
        if old_id_list # will always be true, check for sorbet's sake
          old_id_list.delete(id)
        end
      end

      @id_to_number[id] = number

      id_list = @number_to_ids[number]
      if id_list
        id_list.push(id)
      else
        @number_to_ids[number] = [id]
      end
    end

    sig { params(id: String).returns(T.nilable(Integer)) }
    def get_number_by_id(id)
      @id_to_number[id]
    end

    sig { params(number: Integer).returns(T.nilable(String)) }
    def get_id_by_number(number)
      id_list = @number_to_ids[number]

      if not id_list
        return nil
      end

      return id_list[0]
    end
  end

  class ValueHash
    extend T::Sig

    sig { returns(HashType) }
    attr_reader :value

    sig { returns(String) }
    attr_reader :hash

    sig { params(value: HashType,
                 value_number_map: ValueNumberMap,
                 id_number_map: IDNumberMap
                ).void
    }
    def initialize(value, value_number_map, id_number_map)
      @value = value

      @value_number_map = value_number_map
      @id_number_map = id_number_map

      @hash = T.let(compute_hash(value), String)
    end

    private

    HashType = T.type_alias { T.any(ValueNumber,
                                    IL::Value,
                                    IL::Expression) }

    sig { params(value: HashType).returns(String) }
    def compute_hash(value)
      if value.is_a?(ValueNumber)
        "#{value.number}"
      elsif value.is_a?(IL::Constant)
        "#{value.type}:#{value.value}"
      elsif value.is_a?(IL::ID)
        # lookup value number for id
        # (if id is defined in another block it may not exist)
        number = @id_number_map.get_number_by_id(value.name)
        if not number
          number = -1 # TODO: is this the proper way to handle this case?
        end
        return "#{number}"
      elsif value.is_a?(IL::BinaryOp)
        left_hash = compute_hash(value.left)
        right_hash = compute_hash(value.right)
        "(#{value.op} #{left_hash} #{right_hash})"
      elsif value.is_a?(IL::UnaryOp)
        "(#{value.op} #{compute_hash(value.value)})"
      else
        raise("Unsupported value type in hash function: #{value.class}")
      end
    end
  end

  class ValueNumber < IL::Value
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :number

    sig { params(number: Integer).void }
    def initialize(number)
      @number = number
    end

    sig { returns(String) }
    def to_s
      "##{@number}"
    end
  end
end
