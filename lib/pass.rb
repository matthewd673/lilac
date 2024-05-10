# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Lilac
  # A Pass represents a process that can be run on an object.
  # Passes should be created once and then reused.
  class Pass
    extend T::Sig
    extend T::Generic
    extend T::Helpers

    abstract!

    sig { abstract.returns(String) }
    def self.id; end
    sig { abstract.returns(String) }
    def self.description; end

    sig { abstract.void }
    def run!; end

    sig { returns(String) }
    def to_s
      "#{self.class.id}: #{self.class.description}"
    end
  end
end
