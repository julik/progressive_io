# -*- encoding: utf-8 -*-

require_relative 'lib/progressive_io'

Gem::Specification.new do |s|
  s.name = "progressive_io"
  s.version = ProgressiveIO::VERSION
  s.authors = ["Julik Tarkhanov"]
  s.email = "me@julik.nl"
  s.description = "A Ruby gem that provides an IO wrapper with progress reporting capabilities. It wraps any IO object and calls a callback with the current offset and total size on each read operation, making it perfect for implementing progress bars or monitoring file operations."
  s.summary = "An IO wrapper that sends reports on the offset to a callback, on each read operation"
  s.homepage = "http://github.com/julik/progressive_io"
  s.license = "MIT"
  s.required_ruby_version = ">= 1.8.7"

  s.files = [
    "CHANGELOG.md",
    "README.md",
    "Rakefile",
    "lib/progressive_io.rb",
    "test/test_progressive_io.rb"
  ]
  
  s.extra_rdoc_files = [
    "README.md"
  ]
  
  s.require_paths = ["lib"]

  s.add_development_dependency "rake", "~> 0.0"
  s.add_development_dependency "flexmock", "~> 0.8"
  s.add_development_dependency "minitest", "~> 5.0"
end

