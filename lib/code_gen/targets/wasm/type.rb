# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "wasm"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        IntegerType = T.type_alias { T.any(Type::I32, Type::I64) }
        FloatType = T.type_alias { T.any(Type::F32, Type::F64) }

        class Type < T::Enum
          extend T::Sig

          enums do
            I32 = new("i32")
            I64 = new("i64")
            F32 = new("f32")
            F64 = new("f64")
          end

          sig { returns(String) }
          def to_s
            serialize
          end
        end
      end
    end
  end
end
