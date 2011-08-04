# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.spec 'progressive_io' do | p |
  p.developer('Julik Tarkhanov', 'me@ujulik.nl')
  p.readme_file   = 'README.rdoc'
  p.extra_rdoc_files  = FileList['*.rdoc'] + FileList['*.txt']
  p.extra_dev_deps = {"flexmock" => "~> 0.8"}
  p.clean_globs = File.read(File.dirname(__FILE__) + "/.gitignore").split(/\s/).to_a
end

# vim: syntax=ruby
