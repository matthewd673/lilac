# frozen_string_literal: true

require "minitest/test_task"

task :default do
  sh "srb tc"
  sh "gem build"
end

Minitest::TestTask.create
