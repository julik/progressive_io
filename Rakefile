# -*- ruby -*-

require 'rubygems'
require 'jeweler'
require './lib/progressive_io'

Jeweler::Tasks.new do |gem|
  gem.version = ProgressiveIO::VERSION
  gem.name = "progressive_io"
  gem.summary = "An IO wrapper that sends reports on the offset to a callback, on each read operation"
  gem.email = "me@julik.nl"
  gem.homepage = "http://github.com/julik/progressive_io"
  gem.authors = ["Julik Tarkhanov"]
  gem.license = 'MIT'
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
desc "Run all tests"
Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

task :default => [ :test ]

# vim: syntax=ruby
