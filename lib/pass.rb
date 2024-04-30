# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

# A Pass represents a process that can be run on an object.
# Passes should be created once and then reused.
class Pass
  extend T::Sig
  extend T::Generic
  extend T::Helpers

  abstract!

  sig { abstract.returns(String) }
  def id; end
  sig { abstract.returns(String) }
  def description; end

  sig { returns(String) }
  def to_s
    "#{id}: #{description}"
  end
end
