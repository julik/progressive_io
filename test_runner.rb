#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative 'lib/progressive_io'

# Load all test files
Dir.glob('test/test_*.rb').each do |test_file|
  load test_file
end 