# -*- ruby -*-

desc "Run all tests"
task :test do
  require 'test/unit'
  require_relative 'lib/progressive_io'
  
  # Load all test files
  Dir.glob('test/test_*.rb').each do |test_file|
    load test_file
  end
end

task :default => :test

# vim: syntax=ruby
