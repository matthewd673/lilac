# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Lilac
  # IL contains the classes representing the Lilac Intermediate Language.
  module IL
    extend T::Sig

    # ILObject is a type-alias for any object in the IL that can be
    # "visited". For example, an +IL::Value+ or an +IL::FuncDef+.
    ILObject = T.type_alias do
      T.any(Value, Expression, Statement, FuncParam,
            FuncDef, ExternFuncDef, Program)
    end

    module Type
      # TYPE CATEGORIES

      class Type
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { abstract.returns(String) }
        def to_s; end

        sig { params(other: T.untyped).returns(T::Boolean) }
        def eql?(other)
          self.class == other.class
        end
      end

      class Numeric < Type; end
      class Integer < Numeric; end
      class Signed < Integer; end
      class Unsigned < Integer; end
      class Float < Numeric; end

      # TYPES

      class Void < Type
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "void"
        end
      end

      class U8 < Unsigned
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u8"
        end
      end

      class U16 < Unsigned
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u16"
        end
      end

      class U32 < Unsigned
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u32"
        end
      end

      class U64 < Unsigned
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "u64"
        end
      end

      class I8 < Signed
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i8"
        end
      end

      class I16 < Signed
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i16"
        end
      end

      class I32 < Signed
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i32"
        end
      end

      class I64 < Signed
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "i64"
        end
      end

      class F32 < Float
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "f32"
        end
      end

      class F64 < Float
        extend T::Sig

        sig { override.returns(String) }
        def to_s
          "f64"
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

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end

      sig { abstract.returns(Value) }
      def clone; end
    end

    # A Constant is a constant value of a given type.
    class Constant < Value
      extend T::Sig

      sig { returns(Type::Type) }
      attr_accessor :type

      sig { returns(T.untyped) }
      attr_accessor :value

      sig { params(type: Type::Type, value: T.untyped).void }
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
        @type == Type::Void ? "void" : @value.to_s
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Constant
          return false
        end

        other = T.cast(other, Constant)

        type.eql?(other.type) and value.eql?(other.value)
      end

      sig { override.returns(Constant) }
      def clone
        Constant.new(@type, @value)
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

      sig { returns(Integer) }
      def hash
        @name.hash
      end

      sig { override.returns(ID) }
      def clone
        ID.new(@name)
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

      sig { returns(Integer) }
      def hash
        @number.hash
      end

      sig { override.returns(Register) }
      def clone
        Register.new(@number)
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
          OR  = new("||")
          AND = new("&&")
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

        op.eql?(other.op) and left.eql?(other.left) and right.eql?(other.right)
      end

      sig { override.returns(BinaryOp) }
      def clone
        BinaryOp.new(@op, @left, @right)
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
        when Operator::OR
          left.value != 0 || right.value != 0 ? 1 : 0
        when Operator::AND
          left.value != 0 && right.value != 0 ? 1 : 0
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

        op.eql?(other.op) and value.eql?(other.value)
      end

      sig { override.returns(UnaryOp) }
      def clone
        UnaryOp.new(@op, @value)
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
          0 - value.value
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
        @args.each do |a|
          arg_str += "#{a}, "
        end
        arg_str.chomp!(", ")

        "call #{@func_name}(#{arg_str})"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Call
          return false
        end

        other = T.cast(other, Call)

        func_name.eql?(other.func_name) and args.eql?(other.args)
      end

      sig { override.returns(Call) }
      def clone
        Call.new(@func_name, @args)
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
        @args.each do |a|
          arg_str += "#{a}, "
        end
        arg_str.chomp!(", ")

        "extern_call #{@func_source}.#{@func_name}(#{arg_str})"
      end

      sig { override.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != ExternCall
          return false
        end

        other = T.cast(other, ExternCall)

        func_source.eql?(other.func_source) and
          func_name.eql?(other.func_name) and args.eql?(other.args)
      end

      sig { override.returns(ExternCall) }
      def clone
        ExternCall.new(@func_source, @func_name, @args)
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
        @ids.each do |id|
          ids_str += "#{id.to_s}, "
        end
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

      sig { abstract.params(other: T.untyped).returns(T::Boolean) }
      def eql?(other); end

      sig { abstract.returns(Statement) }
      def clone; end
    end

    # A Definition is a Statement that defines an ID with a type and value.
    class Definition < Statement
      extend T::Sig

      sig { returns(Type::Type) }
      attr_accessor :type

      sig { returns(ID) }
      attr_accessor :id

      sig { returns(T.any(Expression, Value)) }
      attr_accessor :rhs

      sig { params(type: Type::Type, id: ID, rhs: T.any(Expression, Value)).void }
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

        type.eql?(other.type) and id.eql?(other.id) and rhs.eql?(other.rhs)
      end

      sig { override.returns(Definition) }
      def clone
        Definition.new(@type, @id, @rhs)
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

        cond.eql?(other.cond) and target.eql?(other.target)
      end

      sig { override.returns(JumpZero) }
      def clone
        JumpZero.new(@cond, @target)
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

        cond.eql?(other.cond) and target.eql?(other.target)
      end

      sig { override.returns(JumpNotZero) }
      def clone
        JumpNotZero.new(@cond, @target)
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
    end

    # A FuncParam defines a parameter accepted by a FuncDef.
    class FuncParam
      extend T::Sig

      sig { returns(Type::Type) }
      attr_accessor :type

      sig { returns(ID) }
      attr_reader :id

      sig { params(type: Type::Type, id: ID).void }
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

        type.eql?(other.type) and id.eql?(other.id)
      end

      sig { returns(FuncParam) }
      def clone
        FuncParam.new(@type, @id)
      end
    end

    # A FuncDef is a function definition with a name, params, and body.
    class FuncDef
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[FuncParam]) }
      attr_reader :params

      sig { returns(Type::Type) }
      attr_accessor :ret_type

      sig { returns(T::Array[Statement]) }
      attr_reader :stmt_list

      sig do
        params(name: String,
               params: T::Array[FuncParam],
               ret_type: Type::Type,
               stmt_list: T::Array[Statement])
          .void
      end
      def initialize(name, params, ret_type, stmt_list)
        @name = name
        @params = params
        @ret_type = ret_type
        @stmt_list = stmt_list
      end

      sig { returns(String) }
      def to_s
        param_str = ""
        @params.each do |p|
          param_str += "#{p}, "
        end
        param_str.chomp!(", ")

        stmt_str = ""
        @stmt_list.each do |s|
          stmt_str += "#{s}\n"
        end

        "func #{@name}(#{param_str}) -> #{@ret_type}:\n#{stmt_str}\nend"
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != FuncDef
          return false
        end

        other = T.cast(other, FuncDef)

        name.eql?(other.name) and params.eql?(other.params) and
          ret_type.eql?(other.ret_type) and stmt_list.eql?(other.stmt_list)
      end

      sig { returns(FuncDef) }
      def clone
        FuncDef.new(@name, @params, @ret_type, @stmt_list)
      end
    end

    # An ExternFuncDef is a description of a function described elsewhere.
    class ExternFuncDef
      extend T::Sig

      sig { returns(String) }
      attr_reader :source

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Array[Type::Type]) }
      attr_reader :param_types

      sig { returns(Type::Type) }
      attr_accessor :ret_type

      sig do
        params(source: String,
               name: String,
               param_types: T::Array[Type::Type],
               ret_type: Type::Type).void
      end
      def initialize(source, name, param_types, ret_type)
        @source = source
        @name = name
        @param_types = param_types
        @ret_type = ret_type
      end

      sig { returns(String) }
      def key
        "#{@source}##{@name}"
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != ExternFuncDef
          return false
        end

        other = T.cast(other, ExternFuncDef)

        source.eql?(other.source) and name.eql?(other.name) and
          # TODO: if ret_type comparison goes last then this is nilable. Why?
          ret_type.eql?(other.ret_type) and param_types.eql?(other.param_types)
      end

      sig { returns(ExternFuncDef) }
      def clone
        ExternFuncDef.new(@source, @name, @param_types, @ret_type)
      end
    end

    # A Program is a list of Statements and a set of FuncDefs.
    class Program
      extend T::Sig

      sig { returns(T::Array[Statement]) }
      attr_reader :stmt_list

      sig { params(stmt_list: T::Array[Statement]).void }
      # Construct a new Program.
      def initialize(stmt_list: [])
        @stmt_list = stmt_list
        @func_map = T.let({}, T::Hash[String, FuncDef])
        @extern_func_map = T.let({}, T::Hash[String, ExternFuncDef])
      end

      sig { params(funcdef: FuncDef).void }
      def add_func(funcdef)
        @func_map[funcdef.name] = funcdef
      end

      sig { params(block: T.proc.params(arg0: FuncDef).void).void }
      def each_func(&block)
        @func_map.each_key do |k|
          yield T.unsafe(@func_map[k])
        end
      end

      sig { params(name: String).returns(T.nilable(FuncDef)) }
      def get_func(name)
        @func_map[name]
      end

      sig { params(extern_funcdef: ExternFuncDef).void }
      def add_extern_func(extern_funcdef)
        @extern_func_map[extern_funcdef.key] = extern_funcdef
      end

      sig { params(block: T.proc.params(arg0: ExternFuncDef).void).void }
      def each_extern_func(&block)
        @extern_func_map.each_key do |k|
          yield T.unsafe(@extern_func_map[k])
        end
      end

      sig { params(key: String).returns(T.nilable(ExternFuncDef)) }
      def get_extern_func(key)
        @extern_func_map[key]
      end

      sig { returns(String) }
      def to_s
        str = ""
        @stmt_list.each do |i|
          str += "#{i.to_s}\n"
        end
        str
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != Program
          return false
        end

        other = T.cast(other, Program)

        stmt_list.eql?(other.stmt_list) and func_map.eql?(other.func_map) and
          extern_func_map.eql?(other.extern_func_map)
      end

      sig { returns(Program) }
      def clone
        new_program = Program.new(stmt_list: @stmt_list)
        each_func do |f|
          new_program.add_func(f)
        end
        each_extern_func do |f|
          new_program.add_extern_func(f)
        end

        new_program
      end

      protected

      sig { returns(T::Hash[String, FuncDef]) }
      def func_map
        @func_map
      end

      sig { returns(T::Hash[String, ExternFuncDef]) }
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

      sig { returns(Type::Type) }
      attr_reader :ret_type

      sig { returns(Analysis::CFG) }
      attr_reader :cfg

      sig do
        params(name: String,
               params: T::Array[FuncParam],
               ret_type: Type::Type,
               cfg: Analysis::CFG)
          .void
      end
      def initialize(name, params, ret_type, cfg)
        @name = name
        @params = params
        @ret_type = ret_type
        @cfg = cfg
      end

      # TODO: implement to_s

      # TODO: implement eql?

      # TODO: implement clone
    end

    # A CFGProgram is a Program whose instructions are stored in CFGs.
    class CFGProgram
      extend T::Sig

      sig { returns(Analysis::CFG) }
      attr_reader :cfg

      sig { params(cfg: Analysis::CFG).void }
      def initialize(cfg)
        @cfg = cfg
        @func_map = T.let({}, T::Hash[String, CFGFuncDef])
        @extern_func_map = T.let({}, T::Hash[String, ExternFuncDef])
      end

      sig { params(program: Program).returns(CFGProgram) }
      def self.from_program(program)
        # convert main program stmt list to bb and cfg
        main_bb = Analysis::BB.from_stmt_list(program.stmt_list)
        main_cfg = Analysis::CFG.new(blocks: main_bb)

        # create CFGProgram from main
        cfg_program = CFGProgram.new(main_cfg)

        # convert all functions to cfg and add them
        program.each_func do |f|
          func_bb = Analysis::BB.from_stmt_list(f.stmt_list)
          func_cfg = Analysis::CFG.new(blocks: func_bb)
          cfg_funcdef = CFGFuncDef.new(f.name, f.params, f.ret_type, func_cfg)

          cfg_program.add_func(cfg_funcdef)
        end

        # add all extern functions (which have no body so don't need conversion)
        program.each_extern_func do |f|
          cfg_program.add_extern_func(f)
        end

        cfg_program
      end

      sig { params(cfg_funcdef: CFGFuncDef).void }
      def add_func(cfg_funcdef)
        @func_map[cfg_funcdef.name] = cfg_funcdef
      end

      sig { params(block: T.proc.params(arg0: CFGFuncDef).void).void }
      def each_func(&block)
        @func_map.each_key do |k|
          yield T.unsafe(@func_map[k])
        end
      end

      sig { params(name: String).returns(T.nilable(CFGFuncDef)) }
      def get_func(name)
        @func_map[name]
      end

      sig { params(extern_funcdef: ExternFuncDef).void }
      def add_extern_func(extern_funcdef)
        @extern_func_map[extern_funcdef.key] = extern_funcdef
      end

      sig { params(block: T.proc.params(arg0: ExternFuncDef).void).void }
      def each_extern_func(&block)
        @extern_func_map.each_key do |k|
          yield T.unsafe(@extern_func_map[k])
        end
      end

      sig { params(key: String).returns(T.nilable(ExternFuncDef)) }
      def get_extern_func(key)
        @extern_func_map[key]
      end

      # TODO: implement to_s

      # TODO: implement eql?

      # TODO: implement clone

      protected

      sig { returns(T::Hash[String, CFGFuncDef]) }
      def func_map
        @func_map
      end
    end
  end
end
