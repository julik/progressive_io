# progressive_io

* http://github.com/julik/progressive_io

## DESCRIPTION

A wrapper for IO objects that allows a callback to be set which is called when an object is read from.

## FEATURES/PROBLEMS

* Wraps any IO

## SYNOPSIS

```ruby
require "progressive_io"

io = ProgressiveIO.new(File.open("/bigfile.dat")) do | pos |
  puts "Read %d bytes" % [ pos ]
end

# Then, elsewhere deep in the calling code...
io.each do | line | # Each yielded line will call the callback block
   # Do stuff
end
```

For example, you can make any IO a provider for a [progressbar](http://rubygems.org/gem/progressbar):

```ruby
require "progressive_io"
require "progressbar"

# If you know the total size, you can create a progress bar
total_size = File.size("/bigfile.dat")
pbar = Progressbar.new("Pumping data", total_size)
io_with_progress = ProgressiveIO.new(File.open("/bigfile.dat")) { |pos| pbar.set(pos) }

# Then, elsewhere deep in the calling code...
io_with_progress.each do | line | # Each yielded line will call the callback block
   # Each read operation will properly advance the progressbar
end
```

## REQUIREMENTS

* Ruby 1.8.6+

## INSTALL

```bash
gem install progressive_io
```

## LICENSE

(The MIT License)

Copyright (c) 2011 Julik Tarkhanov <me@julik.nl>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 