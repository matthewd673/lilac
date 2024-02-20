# typed: strict
require "sorbet-runtime"
require_relative "optimization"

module Runner
  extend T::Sig

  sig { params(opt: Optimization).void }
  def self.run_pass(opt)
    # TODO: temp
    Kernel::puts("[#{opt.id}] #{opt.full_name}")
  end
end
