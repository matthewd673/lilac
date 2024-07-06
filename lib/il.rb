# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "code_gen/instruction"

module Lilac
  # IL contains the classes representing the Lilac Intermediate Language.
  module IL
    extend T::Sig

    # ILObject is a type-alias for any object in the IL that can be
    # "visited". For example, an +IL::Value+ or an +IL::FuncDef+.
    ILObject = T.type_alias do
      T.any(Value, Expression, Statement, Component, FuncParam, Program)
    end

    # The Types module contains all the types and categories of types available
    # in the Lilac IL.
    module Types
      # TYPE CATEGORIES

      # Represents any type in the IL.
      class Type
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { abstract.returns(String) }
        def to_s; end

        sig { abstract.returns(Integer) }
        def size; end

        sig { params(other: T.untyped).returns(T::Boolean) }
        def ==(other)
          self.class == other.class
        end

        sig { params(other: T.untyped).returns(T::Boolean) }
        def eql?(other)
          self == other
        end

        sig { returns(Integer) }
        def hash
          self.class.hash
        end
      end

      # Represents any numeric type (integer or floating-point).
      class NumericType < Type
        abstract!
      end

      # Represents any integer type (signed or unsigned).
      class IntegerType < NumericType
        abstract!
      end

      # Represents any signed integer type.
      class SignedType < IntegerType
        abstract!
      end

      # Represents any unsigned integer type.
      class UnsignedType < IntegerType
        abstract!
      end

      # Represents any floating-point type.
      class FloatType < NumericType
        abstract!
      end

      # TYPES

      class Void < Type
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "void"
        end

        sig { override.returns(Integer) }
        def size
          0 # TODO: void shouldn't really have a size
        end
      end

      class U8 < UnsignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u8"
        end

        sig { override.returns(Integer) }
        def size
          1
        end
      end

      class U16 < UnsignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u16"
        end

        sig { override.returns(Integer) }
        def size
          2
        end
      end

      class U32 < UnsignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u32"
        end

        sig { override.returns(Integer) }
        def size
          4
        end
      end

      class U64 < UnsignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u64"
        end

        sig { override.returns(Integer) }
        def size
          8
        end
      end

      class I8 < SignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i8"
        end

        sig { override.returns(Integer) }
        def size
          1
        end
      end

      class I16 < SignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i16"
        end

        sig { override.returns(Integer) }
        def size
          2
        end
      end

      class I32 < SignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i32"
        end

        sig { override.returns(Integer) }
        def size
          4
        end
      end

      class I64 < SignedType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i64"
        end

        sig { override.returns(Integer) }
        def size
          8
        end
      end

      class F32 < FloatType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "f32"
        end

        sig { override.returns(Integer) }
        def size
          4
        end
      end

      class F64 < FloatType
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "f64"
        end

        sig { override.returns(Integer) }
        def size
          8
        end
      end

      class Pointer < Type
        extend T::Sig

        sig { returns(Type) }
        attr_reader :type

        sig { params(type: Type).void }
        def initialize(type)
          @type = type
        end

        sig { override.returns(String) }
        def to_s
          "*#{@type}"
        end

        sig { override.returns(Integer) }
        def size
          raise "TODO: implement Pointer size"
        end

        sig { params(other: T.untyped).returns(T::Boolean) }
        def ==(other)
          if other.class != Pointer
            return false
          end

          type == other.type
        end

        sig { returns(Integer) }
        def hash
          [self.class, type].hash
        end
      end
    end

    # A Value is anything that can correspond to a typed value in the IL
    # such as constants and variables.
    class Value
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.returns(String) }
      def to_s; end

      sig { abstract.returns(Integer) }
      def hash; end

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end

      sig { abstract.returns(Value) }
      def clone; end
    end

    # A Constant is a constant value of a given type.
    class Constant < Value
      extend T::Sig

      sig { returns(Types::Type) }
      attr_accessor :type

      sig { returns(T.untyped) }
      attr_accessor :value

      sig { params(type: Types::Type, value: T.untyped).void }
      # Construct a new Constant.
      #
      # @param [Type] type The IL Type of the Constant.
      # @param value The value of the Constant. Not type-checked.
      def initialize(type, value)
        @type = type
        @value = value
      end

      sig { override.returns(String) }
      def to_s
        @type == Types::Void ? "void" : @value.to_s
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Constant
          return false
        end

        other = T.cast(other, Constant)

        type.eql?(other.type) && value.eql?(other.value)
      end

      sig { override.returns(Constant) }
      def clone
        Constant.new(@type, @value)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @type, @value].hash
      end
    end

    # An ID is the name of a variable. When implemented these will often store
    # a type and a value.
    class ID < Value
      extend T::Sig

      sig { returns(String) }
      # The name of the ID.
      attr_reader :name

      sig { params(name: String).void }
      # Construct a new ID.
      #
      # @param [String] name The name of the ID.
      def initialize(name)
        @name = name
      end

      sig { override.returns(String) }
      def to_s
        @name
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != ID
          return false
        end

        other = T.cast(other, ID)

        name.eql?(other.name)
      end

      sig { override.returns(ID) }
      def clone
        ID.new(@name)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @name].hash
      end
    end

    # A Register is a type of ID used in the IL to keep track of temporary
    # values such as intermediate steps of computation. Registers are numbered,
    # not named (though as IDs they still have a name attribute).
    class Register < ID
      extend T::Sig

      sig { returns(Integer) }
      attr_reader :number

      sig { params(number: Integer).void }
      # Construct a new Register.
      #
      # @param [Integer] number The number of the Register.
      def initialize(number)
        @number = number
        @name = "%#{number}"
      end

      sig { override.returns(String) }
      def to_s
        "%#{@number}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Register
          return false
        end

        other = T.cast(other, Register)

        number.eql?(other.number)
      end

      sig { override.returns(Register) }
      def clone
        Register.new(@number)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @number].hash
      end
    end

    # An Expression is any in-built function in the IL such as common
    # arithmetic operations. Expressions cannot be nested.
    class Expression
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.returns(String) }
      def to_s; end

      sig { abstract.returns(Integer) }
      def hash; end

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end

      sig { abstract.returns(Expression) }
      def clone; end
    end

    # A BinaryOp is an Expression which computes a value from two operands.
    # The two operands must have the same type.
    class BinaryOp < Expression
      extend T::Sig

      # A +BinaryOp::Operator+ represents all of the possible operators that
      # can be used in a BinaryOp Expression.
      class Operator < T::Enum
        extend T::Sig

        enums do
          ADD = new("+")
          SUB = new("-")
          MUL = new("*")
          DIV = new("/")
          EQ  = new("==")
          NEQ = new("!=")
          LT  = new("<")
          GT  = new(">")
          LEQ = new("<=")
          GEQ = new(">=")
          BOOL_AND = new("&&")
          BOOL_OR = new("||")
          BIT_LS = new("<<")
          BIT_RS = new(">>")
          BIT_AND = new("&")
          BIT_OR = new("|")
          BIT_XOR = new("^")
        end

        sig { returns(String) }
        def to_s
          serialize
        end
      end

      sig { returns(Operator) }
      attr_reader :op

      sig { returns(Value) }
      attr_accessor :left

      sig { returns(Value) }
      attr_accessor :right

      sig { params(op: Operator, left: Value, right: Value).void }
      # Construct a new BinaryOp.
      #
      # @param [Operator] op The binary operator.
      # @param [Value] left The left operand.
      # @param [Value] right The right operand.
      def initialize(op, left, right)
        @op = op
        @left = left
        @right = right
      end

      sig { override.returns(String) }
      def to_s
        "#{@left} #{@op} #{@right}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != BinaryOp
          return false
        end

        other = T.cast(other, BinaryOp)

        op.eql?(other.op) && left.eql?(other.left) && right.eql?(other.right)
      end

      sig { override.returns(BinaryOp) }
      def clone
        BinaryOp.new(@op, @left, @right)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @op, @left, @right].hash
      end

      sig { returns(T.untyped) }
      def calculate
        # calculations can only be performed on constants
        if !@left.is_a?(Constant) || !@right.is_a?(Constant)
          return nil
        end

        left = @left
        right = @right

        case @op
        when Operator::ADD
          left.value + right.value
        when Operator::SUB
          left.value - right.value
        when Operator::MUL
          left.value * right.value
        when Operator::DIV
          left.value / right.value
        when Operator::EQ
          left.value == right.value ? 1 : 0
        when Operator::NEQ
          left.value != right.value ? 1 : 0
        when Operator::LT
          left.value < right.value ? 1 : 0
        when Operator::GT
          left.value > right.value ? 1 : 0
        when Operator::LEQ
          left.value <= right.value ? 1 : 0
        when Operator::GEQ
          left.value >= right.value ? 1 : 0
        when Operator::BOOL_AND
          left.value != 0 && right.value != 0 ? 1 : 0
        when Operator::BOOL_OR
          left.value != 0 || right.value != 0 ? 1 : 0
        when Operator::BIT_LS
          left.value << right.value
        when Operator::BIT_RS
          left.value >> right.value # TODO: is this logical shift?
        when Operator::BIT_AND
          left.value & right.value
        when Operator::BIT_OR
          left.value | right.value
        when Operator::BIT_XOR
          left.value ^ right.value
        else T.absurd(self)
        end
      end
    end

    # A UnaryOp is an Expression which computes a value from one operand.
    class UnaryOp < Expression
      extend T::Sig

      # A +UnaryOp::Operator+ represents all of the possible operators that
      # can be used in a UnaryOp Expression.
      class Operator < T::Enum
        extend T::Sig

        enums do
          NEG = new("-@")
          BOOL_NOT = new("!@")
          BIT_NOT = new("~@")
        end

        sig { returns(String) }
        def to_s
          serialize
        end
      end

      sig { returns(Operator) }
      attr_reader :op

      sig { returns(Value) }
      attr_accessor :value

      sig { params(op: Operator, value: Value).void }
      # Construct a new UnaryOp.
      #
      # @param [Operator] op The unary operator.
      # @param [Value] value The value being operated on.
      def initialize(op, value)
        @op = op
        @value = value
      end

      sig { override.returns(String) }
      def to_s
        "#{@op}#{@value}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != UnaryOp
          return false
        end

        other = T.cast(other, UnaryOp)

        op.eql?(other.op) && value.eql?(other.value)
      end

      sig { override.returns(UnaryOp) }
      def clone
        UnaryOp.new(@op, @value)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @op, @value].hash
      end

      sig { returns(T.untyped) }
      def calculate
        # calculations can only be performed on constants
        unless @value.is_a?(Constant)
          return nil
        end

        value = @value

        case @op
        when Operator::NEG
          -value.value
        when Operator::BOOL_NOT
          value.value != 0 ? 0 : 1
        when Operator::BIT_NOT
          ~value.value
        else T.absurd(self)
        end
      end
    end

    # A Call is an Expression that represents a function call.
    class Call < Expression
      extend T::Sig

      sig { returns(String) }
      attr_reader :func_name

      sig { returns(T::Array[Value]) }
      attr_reader :args

      sig { params(func_name: String, args: T::Array[Value]).void }
      def initialize(func_name, args)
        @func_name = func_name
        @args = args
      end

      sig { override.returns(String) }
      def to_s
        arg_str = "".dup
        @args.each { |a| arg_str += "#{a}, " }
        arg_str.chomp!(", ")

        "call #{@func_name}(#{arg_str})"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Call
          return false
        end

        other = T.cast(other, Call)

        func_name.eql?(other.func_name) && args.eql?(other.args)
      end

      sig { override.returns(Call) }
      def clone
        Call.new(@func_name, @args)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @func_name, @args].hash
      end
    end

    # An ExternCall is an Expression that represents a call to an external
    # function.
    class ExternCall < Call
      extend T::Sig

      sig { returns(String) }
      attr_reader :func_source

      sig do
        params(func_source: String,
               func_name: String,
               args: T::Array[Value]).void
      end
      def initialize(func_source, func_name, args)
        @func_source = func_source
        @func_name = func_name
        @args = args
      end

      sig { override.returns(String) }
      def to_s
        arg_str = ""
        @args.each { |a| arg_str += "#{a}, " }
        arg_str.chomp!(", ")

        "extern_call #{@func_source}.#{@func_name}(#{arg_str})"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != ExternCall
          return false
        end

        other = T.cast(other, ExternCall)

        func_source.eql?(other.func_source) &&
          func_name.eql?(other.func_name) && args.eql?(other.args)
      end

      sig { override.returns(ExternCall) }
      def clone
        ExternCall.new(@func_source, @func_name, @args)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @func_source, @func_name, @args].hash
      end
    end

    # A Phi function is an Expression that combines multiple possible SSA
    # values at a join node.
    class Phi < Expression
      sig { returns(T::Array[ID]) }
      attr_reader :ids

      sig { params(ids: T::Array[ID]).void }
      def initialize(ids)
        @ids = ids
      end

      sig { override.returns(String) }
      def to_s
        ids_str = ""
        @ids.each { |id| ids_str += "#{id.to_s}, " }
        ids_str.chomp!(", ")

        "phi (#{ids_str})"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Phi
          return false
        end

        other = T.cast(other, Phi)

        ids.eql?(other.ids)
      end

      sig { override.returns(Phi) }
      def clone
        Phi.new(@ids)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @ids].hash
      end
    end

    # A Statement is a single instruction or "line of code" in the IL.
    class Statement
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T.nilable(String)) }
      attr_accessor :annotation

      sig { abstract.returns(String) }
      def to_s; end

      sig { abstract.returns(Integer) }
      def hash; end

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end

      sig { abstract.returns(Statement) }
      def clone; end
    end

    # A Definition is a Statement that defines an ID with a type and value.
    class Definition < Statement
      extend T::Sig

      sig { returns(Types::Type) }
      attr_accessor :type

      sig { returns(ID) }
      attr_accessor :id

      sig { returns(T.any(Expression, Value)) }
      attr_accessor :rhs

      sig do
        params(type: Types::Type, id: ID, rhs: T.any(Expression, Value)).void
      end
      # Construct a new Definition.
      #
      # @param [Type] type The type of the ID.
      # @param [ID] id The ID.
      # @param [T.any(Expression, Value)] rhs The right hand side of
      # the assignment.
      def initialize(type, id, rhs)
        @type = type
        @id = id
        @rhs = rhs
      end

      sig { override.returns(String) }
      def to_s
        "#{@type} #{@id} = #{@rhs}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Definition
          return false
        end

        other = T.cast(other, Definition)

        type.eql?(other.type) && id.eql?(other.id) && rhs.eql?(other.rhs)
      end

      sig { override.returns(Definition) }
      def clone
        Definition.new(@type, @id, @rhs)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @type, @id, @rhs].hash
      end
    end

    # A Label is a Statement that does nothing but can be jumped to by a Jump.
    class Label < Statement
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String).void }
      # Construct a new Label.
      #
      # @param [String] name The name of the Label.
      def initialize(name)
        @name = name
      end

      sig { override.returns(String) }
      def to_s
        "#{@name}:"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Label
          return false
        end

        other = T.cast(other, Label)

        name.eql?(other.name)
      end

      sig { override.returns(Label) }
      def clone
        Label.new(@name)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @name].hash
      end
    end

    # A Jump is a Statement that will jump to the target Label unconditionally.
    class Jump < Statement
      extend T::Sig

      sig { returns(String) }
      attr_accessor :target

      sig { params(target: String).void }
      # Construct a new Jump.
      #
      # @param [String] target The name of the target Label of the Jump.
      def initialize(target)
        @target = target
      end

      sig { override.returns(String) }
      def to_s
        "jmp #{@target}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Jump
          return false
        end

        other = T.cast(other, Jump)

        target.eql?(other.target)
      end

      sig { override.returns(Jump) }
      def clone
        Jump.new(@target)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @target].hash
      end
    end

    # A JumpZero is a Jump that will jump to the target Label only when its
    # conditional value is equal to +0+.
    class JumpZero < Jump
      extend T::Sig

      sig { returns(Value) }
      attr_accessor :cond

      sig { params(cond: Value, target: String).void }
      # Construct a new JumpZero.
      #
      # @param [Value] cond The value of the JumpZero's condition.
      # @param [String] target The name of the target Label of the JumpZero.
      def initialize(cond, target)
        @cond = cond
        @target = target
      end

      sig { override.returns(String) }
      def to_s
        "jz #{@cond} #{@target}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != JumpZero
          return false
        end

        other = T.cast(other, JumpZero)

        cond.eql?(other.cond) && target.eql?(other.target)
      end

      sig { override.returns(JumpZero) }
      def clone
        JumpZero.new(@cond, @target)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @cond, @target].hash
      end
    end

    # A JumpNotZero is a Jump that will jump to the target Label only when its
    # conditional value is _not_ equal to +0+.
    class JumpNotZero < Jump
      extend T::Sig

      sig { returns(Value) }
      attr_accessor :cond

      sig { params(cond: Value, target: String).void }
      # Construct a new JumpNotZero.
      #
      # @param [Value] cond The value of the JumpNotZero's condition.
      # @param [String] target The name of the target Label of the JumpNotZero.
      def initialize(cond, target)
        @cond = cond
        @target = target
      end

      sig { override.returns(String) }
      def to_s
        "jnz #{@cond} #{@target}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != JumpNotZero
          return false
        end

        other = T.cast(other, JumpNotZero)

        cond.eql?(other.cond) && target.eql?(other.target)
      end

      sig { override.returns(JumpNotZero) }
      def clone
        JumpNotZero.new(@cond, @target)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @cond, @target].hash
      end
    end

    # A Return statement is used to return a value from within a FuncDef.
    class Return < Statement
      extend T::Sig

      sig { returns(Value) }
      attr_reader :value

      sig { params(value: Value).void }
      def initialize(value)
        @value = value
      end

      sig { override.returns(String) }
      def to_s
        "ret #{@value}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Return
          return false
        end

        other = T.cast(other, Return)

        value.eql?(other.value)
      end

      sig { override.returns(Return) }
      def clone
        Return.new(@value)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @value].hash
      end
    end

    # A VoidCall statement is used to call a +Void+ function without expecting
    # any output.
    class VoidCall < Statement
      extend T::Sig

      sig { returns(Call) }
      attr_reader :call

      sig { params(call: Call).void }
      def initialize(call)
        @call = call
      end

      sig { override.returns(String) }
      def to_s
        "void #{@call}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != VoidCall
          return false
        end

        other = T.cast(other, VoidCall)

        call.eql?(other.call)
      end

      sig { override.returns(VoidCall) }
      def clone
        VoidCall.new(@call)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @call].hash
      end
    end

    # An InlineInstruction statement is used to include an explicit
    # machine-dependent instruction in an IL Program.
    class InlineInstruction < Statement
      extend T::Sig

      sig { returns(String) }
      attr_reader :target

      sig { returns(CodeGen::Instruction) }
      attr_reader :instruction

      sig { params(target: String, instruction: CodeGen::Instruction).void }
      # Construct a new InlineAssembly statement.
      #
      # @param [String] target The machine that this instruction is targeting.
      # @param [String] instruction The machine-dependent instruction to
      #   include.
      def initialize(target, instruction)
        @target = target
        @instruction = instruction
      end

      sig { override.returns(String) }
      def to_s
        "asm #{target} `#{instruction}`"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != InlineInstruction
          return false
        end

        other = T.cast(other, InlineInstruction)

        @target.eql?(other.target) && @instruction.eql?(other.instruction)
      end

      sig { override.returns(InlineInstruction) }
      def clone
        InlineInstruction.new(@target, @instruction)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @target, @instruction].hash
      end
    end

    # A Component is something that appears at the top level of a Program
    # like a global variable or a function definition.
    class Component
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.returns(String) }
      def to_s; end

      sig { abstract.returns(Integer) }
      def hash; end

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end

      sig { abstract.returns(Component) }
      def clone; end
    end

    # A GlobalDef is a Component that defines a new global variable in a
    # Program.
    class GlobalDef < Component
      extend T::Sig

      sig { returns(Types::Type) }
      attr_reader :type

      sig { returns(ID) }
      attr_reader :id

      sig { returns(Constant) }
      attr_reader :rhs

      sig { params(type: Types::Type, id: ID, rhs: Constant).void }
      def initialize(type, id, rhs)
        @type = type
        @id = id
        @rhs = rhs
      end

      sig { override.returns(String) }
      def to_s
        "global #{@type} #{@id} = #{@rhs}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != GlobalDef
          return false
        end

        other = T.cast(other, GlobalDef)

        @type.eql?(other.type) && @id.eql?(other.id) && @rhs.eql?(other.rhs)
      end

      sig { override.returns(GlobalDef) }
      def clone
        GlobalDef.new(@type, @id, @rhs)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @type, @id, @rhs].hash
      end
    end

    # A FuncDef is a function definition with a name, params, and body.
    class FuncDef < Component
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[FuncParam]) }
      attr_reader :params

      sig { returns(Types::Type) }
      attr_accessor :ret_type

      sig { returns(T::Array[Statement]) }
      attr_reader :stmt_list

      sig { returns(T::Boolean) }
      attr_accessor :exported

      sig do
        params(name: String,
               params: T::Array[FuncParam],
               ret_type: Types::Type,
               stmt_list: T::Array[Statement],
               exported: T::Boolean)
          .void
      end
      def initialize(name, params, ret_type, stmt_list, exported: false)
        @name = name
        @params = params
        @ret_type = ret_type
        @stmt_list = stmt_list
        @exported = exported
      end

      sig { override.returns(String) }
      def to_s
        param_str = ""
        @params.each { |p| param_str += "#{p}, " }
        param_str.chomp!(", ")

        stmt_str = ""
        @stmt_list.each { |s| stmt_str += "#{s}\n" }

        "func #{@name}(#{param_str}) -> #{@ret_type}:\n#{stmt_str}\nend"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != FuncDef
          return false
        end

        other = T.cast(other, FuncDef)

        name.eql?(other.name) && params.eql?(other.params) &&
          ret_type.eql?(other.ret_type) && stmt_list.eql?(other.stmt_list)
      end

      sig { override.returns(FuncDef) }
      def clone
        FuncDef.new(@name, @params, @ret_type, @stmt_list)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @name, @params, @ret_type, @stmt_list].hash
      end
    end

    # A FuncParam defines a parameter accepted by a FuncDef.
    class FuncParam
      extend T::Sig

      sig { returns(Types::Type) }
      attr_accessor :type

      sig { returns(ID) }
      attr_reader :id

      sig { params(type: Types::Type, id: ID).void }
      def initialize(type, id)
        @type = type
        @id = id
      end

      sig { returns(String) }
      def to_s
        "#{@type} #{@id}"
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != FuncParam
          return false
        end

        other = T.cast(other, FuncParam)

        type.eql?(other.type) && id.eql?(other.id)
      end

      sig { returns(FuncParam) }
      def clone
        FuncParam.new(@type, @id)
      end

      sig { returns(Integer) }
      def hash
        [self.class, @type, @id].hash
      end
    end

    # An ExternFuncDef is a description of a function described elsewhere.
    class ExternFuncDef < Component
      extend T::Sig

      sig { returns(String) }
      attr_reader :source

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[Types::Type]) }
      attr_reader :param_types

      sig { returns(Types::Type) }
      attr_accessor :ret_type

      sig do
        params(source: String,
               name: String,
               param_types: T::Array[Types::Type],
               ret_type: Types::Type).void
      end
      def initialize(source, name, param_types, ret_type)
        @source = source
        @name = name
        @param_types = param_types
        @ret_type = ret_type
      end

      sig { override.returns(String) }
      def to_s
        param_str = ""
        @param_types.each { |t| param_str += "#{t}, " }
        param_str.chomp!(", ")

        "extern func #{@source} #{@name}(#{param_str}) -> #{@ret_type}"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != ExternFuncDef
          return false
        end

        other = T.cast(other, ExternFuncDef)

        source.eql?(other.source) && name.eql?(other.name) &&
          # TODO: if ret_type comparison goes last then this is nilable. Why?
          ret_type.eql?(other.ret_type) && param_types.eql?(other.param_types)
      end

      sig { override.returns(ExternFuncDef) }
      def clone
        ExternFuncDef.new(@source, @name, @param_types, @ret_type)
      end

      sig { override.returns(Integer) }
      def hash
        [self.class, @source, @name, @param_types, @ret_type].hash
      end
    end

    # A Program is a list of Statements and a set of FuncDefs.
    class Program
      extend T::Sig

      sig { void }
      # Construct a new Program.
      def initialize
        @global_map = T.let({}, T::Hash[String, GlobalDef])
        @func_map = T.let({}, T::Hash[String, FuncDef])
        @extern_func_map = T.let({}, T::Hash[[String, String], ExternFuncDef])
      end

      sig { params(globaldef: GlobalDef).void }
      def add_global(globaldef)
        @global_map[globaldef.id.name] = globaldef
      end

      sig { params(block: T.proc.params(arg0: GlobalDef).void).void }
      def each_global(&block)
        @global_map.each_key { |k| yield T.unsafe(@global_map[k]) }
      end

      sig { params(name: String).returns(T.nilable(GlobalDef)) }
      def get_global(name)
        @global_map[name]
      end

      sig { params(funcdef: FuncDef).void }
      def add_func(funcdef)
        @func_map[funcdef.name] = funcdef
      end

      sig { params(block: T.proc.params(arg0: FuncDef).void).void }
      def each_func(&block)
        @func_map.each_key { |k| yield T.unsafe(@func_map[k]) }
      end

      sig { params(name: String).returns(T.nilable(FuncDef)) }
      def get_func(name)
        @func_map[name]
      end

      sig { params(extern_funcdef: ExternFuncDef).void }
      def add_extern_func(extern_funcdef)
        key = [extern_funcdef.source, extern_funcdef.name]
        @extern_func_map[key] = extern_funcdef
      end

      sig { params(block: T.proc.params(arg0: ExternFuncDef).void).void }
      def each_extern_func(&block)
        @extern_func_map.each_key { |k| yield T.unsafe(@extern_func_map[k]) }
      end

      sig do
        params(source: String, name: String).returns(T.nilable(ExternFuncDef))
      end
      def get_extern_func(source, name)
        @extern_func_map[[source, name]]
      end

      sig { returns(String) }
      def to_s
        "IL::Program" # TODO: improve to_s
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Program
          return false
        end

        other = T.cast(other, Program)

        global_map.eql?(other.global_map) &&
          func_map.eql?(other.func_map) &&
          extern_func_map.eql?(other.extern_func_map)
      end

      sig { returns(Program) }
      def clone
        new_program = Program.new
        each_global { |g| new_program.add_global(g) }
        each_func { |f| new_program.add_func(f) }
        each_extern_func { |f| new_program.add_extern_func(f) }

        new_program
      end

      sig { returns(Integer) }
      def hash
        [self.class, @global_map, @func_map, @extern_func_map].hash
      end

      protected

      sig { returns(T::Hash[String, GlobalDef]) }
      def global_map
        @global_map
      end

      sig { returns(T::Hash[String, FuncDef]) }
      def func_map
        @func_map
      end

      sig { returns(T::Hash[[String, String], ExternFuncDef]) }
      def extern_func_map
        @extern_func_map
      end
    end

    # A CFGFuncDef is a FuncDef whose instructions are stored in a CFG.
    class CFGFuncDef
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[FuncParam]) }
      attr_reader :params

      sig { returns(Types::Type) }
      attr_reader :ret_type

      sig { returns(Analysis::CFG) }
      attr_reader :cfg

      sig { returns(T::Boolean) }
      attr_accessor :exported

      sig do
        params(name: String,
               params: T::Array[FuncParam],
               ret_type: Types::Type,
               cfg: Analysis::CFG,
               exported: T::Boolean)
          .void
      end
      def initialize(name, params, ret_type, cfg, exported: false)
        @name = name
        @params = params
        @ret_type = ret_type
        @cfg = cfg
        @exported = exported
      end

      # TODO: implement to_s

      # TODO: implement eql?

      # TODO: implement clone

      # TODO: implement hash
    end

    # A CFGProgram is a Program whose instructions are stored in CFGs.
    class CFGProgram
      extend T::Sig

      sig { void }
      def initialize
        @global_map = T.let({}, T::Hash[String, GlobalDef])
        @func_map = T.let({}, T::Hash[String, CFGFuncDef])
        @extern_func_map = T.let({}, T::Hash[[String, String], ExternFuncDef])
      end

      sig { params(program: Program).returns(CFGProgram) }
      def self.from_program(program)
        # create CFGProgram from main
        cfg_program = CFGProgram.new

        # add all global definitions
        program.each_global { |g| cfg_program.add_global(g) }

        # convert all functions to cfg and add them
        program.each_func do |f|
          func_bb = Analysis::BB.from_stmt_list(f.stmt_list)
          func_cfg = Analysis::CFG.new(blocks: func_bb)
          cfg_funcdef = CFGFuncDef.new(f.name,
                                       f.params,
                                       f.ret_type,
                                       func_cfg,
                                       exported: f.exported)

          cfg_program.add_func(cfg_funcdef)
        end

        # add all extern functions (which have no body so don't need conversion)
        program.each_extern_func { |f| cfg_program.add_extern_func(f) }

        cfg_program
      end

      sig { params(globaldef: GlobalDef).void }
      def add_global(globaldef)
        @global_map[globaldef.id.name] = globaldef
      end

      sig { params(block: T.proc.params(arg0: GlobalDef).void).void }
      def each_global(&block)
        @global_map.each_key { |k| yield T.unsafe(@global_map[k]) }
      end

      sig { params(name: String).returns(T.nilable(GlobalDef)) }
      def get_global(name)
        @global_map[name]
      end

      sig { params(cfg_funcdef: CFGFuncDef).void }
      def add_func(cfg_funcdef)
        @func_map[cfg_funcdef.name] = cfg_funcdef
      end

      sig { params(block: T.proc.params(arg0: CFGFuncDef).void).void }
      def each_func(&block)
        @func_map.each_key { |k| yield T.unsafe(@func_map[k]) }
      end

      sig { params(name: String).returns(T.nilable(CFGFuncDef)) }
      def get_func(name)
        @func_map[name]
      end

      sig { params(extern_funcdef: ExternFuncDef).void }
      def add_extern_func(extern_funcdef)
        key = [extern_funcdef.source, extern_funcdef.name]
        @extern_func_map[key] = extern_funcdef
      end

      sig { params(block: T.proc.params(arg0: ExternFuncDef).void).void }
      def each_extern_func(&block)
        @extern_func_map.each_key { |k| yield T.unsafe(@extern_func_map[k]) }
      end

      sig do
        params(source: String, name: String).returns(T.nilable(ExternFuncDef))
      end
      def get_extern_func(source, name)
        @extern_func_map[[source, name]]
      end

      # TODO: implement to_s

      # TODO: implement eql?

      # TODO: implement clone

      # TODO: implement hash

      protected

      sig { returns(T::Hash[String, CFGFuncDef]) }
      def func_map
        @func_map
      end
    end
  end
end
