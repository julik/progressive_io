## 2.1.0

* Report `readpartial`, `read_nonblock`, `sysread`, `getbyte`, `readbyte`, `each_char` and
  `each_codepoint`, which went past the wrapper unreported.
* `IO.copy_stream` reports now. It read a wrapped File by opening its path itself, and a wrapped
  IO through `to_io`, so the wrapper no longer passes on `to_path` or `to_io` - reach the
  wrapped IO with `__getobj__` where you need it (`IO.select`, say). Without them
  `IO.copy_stream` reads through `readpartial`, which also means no zero-copy fast path.
* Pass keyword arguments on: `gets(chomp: true)`, `readline`, `readlines`, `each` and
  `each_line` used to raise `TypeError`.
* Work with pipes and sockets. Every read raised `Errno::ESPIPE`, since reporting asked the IO
  for its position; for a stream without one, the bytes read so far are reported instead, and
  `ungetc`/`ungetbyte` take pushed-back bytes off that count.
* Require Ruby 3.2.

## 2.0.2

* Fix `each_line` to return an Enumerator that properly references `:each_line` method
  when called without a block. Previously, `each_line` was an alias of `each`, causing
  the returned Enumerator to reference `:each` instead of `:each_line`.
* Change `each` and `each_line` to accept variadic arguments (`*args`) for proper
  forwarding of separator and limit parameters.

## 2.0.1

* Revert back to using SimpleDelegator - it's just easier.

## 2.0.0

* Added comprehensive documentation with examples
* Added progress block support for tracking read operations
* Added support for StringIO and other IO-like objects
* Added each_byte method for byte-by-byte iteration with progress tracking
* Added getc method for single character reading with progress tracking
* Added gets method for line reading with progress tracking
* Modernized gem structure and build process
* Switched to Bundler for gem management
* Added Minitest test suite
* Increased minimum Ruby version requirement to 1.8.7

## 1.0.1

* Use Jeweler for build management

## 1.0.0

* First release 