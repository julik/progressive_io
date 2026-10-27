# frozen_string_literal: true

require 'delegate'

# A wrapper class that provides progress tracking for IO operations.
#
# This class wraps an IO object and calls a progress block whenever data is read,
# allowing you to track reading progress for operations like file uploads or downloads.
#
# The block receives the position after each read. A pipe, a socket or a TTY has no position,
# so for those it receives the number of bytes read through the wrapper so far instead.
#
# @example Basic usage with a file
#   file = File.open('large_file.txt')
#   progress_io = ProgressiveIO.new(file) do |current_pos|
#     puts "Read #{current_pos} bytes"
#   end
#
#   progress_io.each_line do |line|
#     # Process each line
#   end
#
# @example Usage with a StringIO
#   string_io = StringIO.new("Hello\nWorld\n")
#   progress_io = ProgressiveIO.new(string_io) do |current_pos|
#     puts "Read #{current_pos} bytes"
#   end
#
#   content = progress_io.read
#
# @example Copying, which reads through readpartial
#   IO.copy_stream(ProgressiveIO.new(source) { |pos| bar.update(pos) }, destination)
#
# @since 2.0.0
class ProgressiveIO < SimpleDelegator
  # The version of the ProgressiveIO library
  VERSION = '2.1.0'

  # @return [Proc, nil] The progress callback block that will be called when data is read
  #   The block receives one parameter: current position
  attr_accessor :progress_block

  # Creates a new ProgressiveIO wrapper around an IO object.
  #
  # @param with_io [IO] The IO object to wrap (File, StringIO, a pipe, etc.)
  # @param blk [Proc, nil] Optional block that will be called when data is read
  #   The block receives one parameter: current position
  # @yield [current_pos] The progress callback
  # @yieldparam current_pos [Integer] The current position in the IO stream, or the bytes
  #   read so far for a stream that has no position
  #
  # @example
  #   file = File.open('data.txt')
  #   progress_io = ProgressiveIO.new(file) do |pos|
  #     puts "Read #{pos} bytes"
  #   end
  def initialize(with_io, &blk)
    super(with_io)
    @progress_block = blk.to_proc if blk
    @positioned = nil
    @consumed = 0
  end

  # Iterates over the IO stream line by line, calling the progress block for each line.
  #
  # @param args [Array] Arguments to pass to the underlying IO#each method (separator and/or limit)
  # @param kwargs [Hash] Keyword arguments to pass on, such as `chomp: true`
  # @yield [line] Each line from the IO stream
  # @yieldparam line [String] A line from the IO stream
  # @return [Enumerator] An enumerator if no block is given
  #
  # @example
  #   progress_io.each do |line|
  #     puts "Processing: #{line.chomp}"
  #   end
  #
  # @example Using as an Enumerator
  #   progress_io.each.with_index do |line, idx|
  #     puts "Line #{idx}: #{line.chomp}"
  #   end
  def each(*args, **kwargs, &blk)
    return enum_for(__method__, *args, **kwargs) unless block_given?

    # Report offset at each call of the iterator
    super(*args, **kwargs) do |line|
      yield(line).tap { notify_read(line, chomped: kwargs[:chomp]) }
    end
  end

  # Iterates over the IO stream line by line, calling the progress block for each line.
  # This is an alias-like method for {#each} that ensures proper Enumerator behavior.
  #
  # @param args [Array] Arguments to pass to the underlying IO#each_line method (separator and/or limit)
  # @param kwargs [Hash] Keyword arguments to pass on, such as `chomp: true`
  # @yield [line] Each line from the IO stream
  # @yieldparam line [String] A line from the IO stream
  # @return [Enumerator] An enumerator if no block is given
  #
  # @example
  #   progress_io.each_line do |line|
  #     puts "Processing: #{line.chomp}"
  #   end
  #
  # @example Using as an Enumerator
  #   progress_io.each_line.with_index do |line, idx|
  #     puts "Line #{idx}: #{line.chomp}"
  #   end
  def each_line(*args, **kwargs, &blk)
    return enum_for(__method__, *args, **kwargs) unless block_given?

    each(*args, **kwargs, &blk)
  end

  # Iterates over the IO stream byte by byte, calling the progress block for each byte.
  #
  # @yield [byte] Each byte from the IO stream
  # @yieldparam byte [Integer] A byte from the IO stream (0-255)
  # @return [Enumerator] An enumerator if no block is given
  #
  # @example
  #   progress_io.each_byte do |byte|
  #     puts "Byte: #{byte}"
  #   end
  #
  # @example Using as an Enumerator
  #   progress_io.each_byte.with_index do |byte, idx|
  #     puts "Byte #{idx}: #{byte}"
  #   end
  def each_byte(&blk)
    return enum_for(__method__) unless block_given?

    # Report offset at each call of the iterator
    super { |b| yield(b).tap { notify_read(b) } }
  end

  # Iterates over the IO stream character by character, calling the progress block for each.
  #
  # @yield [char] Each character from the IO stream
  # @yieldparam char [String] A character from the IO stream
  # @return [Enumerator] An enumerator if no block is given
  # @since 2.1.0
  def each_char(&blk)
    return enum_for(__method__) unless block_given?

    super { |c| yield(c).tap { notify_read(c) } }
  end

  # Iterates over the IO stream codepoint by codepoint, calling the progress block for each.
  #
  # @yield [codepoint] Each codepoint from the IO stream
  # @yieldparam codepoint [Integer] A codepoint from the IO stream
  # @return [Enumerator] An enumerator if no block is given
  # @since 2.1.0
  def each_codepoint(&blk)
    return enum_for(__method__) unless block_given?

    super { |c| yield(c).tap { notify_read(codepoint_string(c)) } }
  end

  # Reads a single character from the IO stream.
  #
  # @return [String, nil] The next character or nil if at end of stream
  # @see IO#getc
  def getc
    super.tap { |c| notify_read(c) }
  end

  # Reads a single byte from the IO stream.
  #
  # @return [Integer, nil] The next byte or nil if at end of stream
  # @see IO#getbyte
  # @since 2.1.0
  def getbyte
    super.tap { |b| notify_read(b) }
  end

  # Reads a line from the IO stream.
  #
  # @param args [Array] Arguments to pass to the underlying IO#gets method
  # @param kwargs [Hash] Keyword arguments to pass on, such as `chomp: true`
  # @return [String, nil] The next line or nil if at end of stream
  # @see IO#gets
  def gets(*args, **kwargs)
    super(*args, **kwargs).tap { |line| notify_read(line, chomped: kwargs[:chomp]) }
  end

  # Reads data from the IO stream.
  #
  # @param a [Array] Arguments to pass to the underlying IO#read method
  # @return [String, nil] The read data or nil if at end of stream
  # @see IO#read
  def read(*a)
    super(*a).tap { |data| notify_read(data) }
  end

  # Reads at most a number of bytes, blocking only if none are available. IO.copy_stream reads
  # through this when its source is not an IO itself.
  #
  # @param a [Array] Arguments to pass to the underlying IO#readpartial method
  # @return [String] The read data
  # @raise [EOFError] If at end of stream
  # @see IO#readpartial
  # @since 2.1.0
  def readpartial(*a)
    super(*a).tap { |data| notify_read(data) }
  end

  # Reads at most a number of bytes without blocking.
  #
  # @param a [Array] Arguments to pass to the underlying IO#read_nonblock method
  # @param kwargs [Hash] Keyword arguments to pass on, such as `exception: false`
  # @return [String, Symbol, nil] The read data, or `:wait_readable` with `exception: false`
  # @see IO#read_nonblock
  # @since 2.1.0
  def read_nonblock(*a, **kwargs)
    super(*a, **kwargs).tap { |data| notify_read(data) }
  end

  # Reads bytes with a low-level read, bypassing buffering.
  #
  # @param a [Array] Arguments to pass to the underlying IO#sysread method
  # @return [String] The read data
  # @raise [EOFError] If at end of stream
  # @see IO#sysread
  # @since 2.1.0
  def sysread(*a)
    super(*a).tap { |data| notify_read(data) }
  end

  # Reads a specific number of bytes from the IO stream.
  #
  # @param a [Array] Arguments to pass to the underlying IO#readbytes method
  # @return [String] The read bytes
  # @see IO#readbytes
  def readbytes(*a)
    super(*a).tap { |data| notify_read(data) }
  end

  # Reads a single byte from the IO stream.
  #
  # @return [Integer] The next byte
  # @raise [EOFError] If at end of stream
  # @see IO#readbyte
  # @since 2.1.0
  def readbyte
    super.tap { |b| notify_read(b) }
  end

  # Reads a single character from the IO stream.
  #
  # @return [String] The next character
  # @raise [EOFError] If at end of stream
  # @see IO#readchar
  def readchar
    super.tap { |c| notify_read(c) }
  end

  # Reads a line from the IO stream.
  #
  # @param a [Array] Arguments to pass to the underlying IO#readline method
  # @param kwargs [Hash] Keyword arguments to pass on, such as `chomp: true`
  # @return [String] The next line
  # @raise [EOFError] If at end of stream
  # @see IO#readline
  def readline(*a, **kwargs)
    super(*a, **kwargs).tap { |line| notify_read(line, chomped: kwargs[:chomp]) }
  end

  # Reads all lines from the IO stream.
  #
  # @param a [Array] Arguments to pass to the underlying IO#readlines method
  # @param kwargs [Hash] Keyword arguments to pass on, such as `chomp: true`
  # @return [Array<String>] Array of lines
  # @see IO#readlines
  def readlines(*a, **kwargs)
    super(*a, **kwargs).tap { |lines| notify_read(lines, chomped: kwargs[:chomp]) }
  end

  # Pushes a character back onto the stream. Not a read, so it is not reported - but on a stream
  # without a position it is taken off the bytes read, so it is not counted twice.
  #
  # @param c [String, Integer] The character to push back
  # @return [nil]
  # @see IO#ungetc
  # @since 2.1.0
  def ungetc(c)
    super(c).tap { unread(c) }
  end

  # Pushes a byte (or bytes) back onto the stream, see {#ungetc}.
  #
  # @param b [String, Integer] The byte or bytes to push back
  # @return [nil]
  # @see IO#ungetbyte
  # @since 2.1.0
  def ungetbyte(b)
    super(b).tap { unread(b) }
  end

  # Conversions the wrapper does not pass on. Given `to_path`, IO.copy_stream opens the file by
  # name itself, and given `to_io` (IO.select and the like too) it reads the wrapped IO directly
  # - past the wrapper either way, with nothing reported. Without them IO.copy_stream reads
  # through {#readpartial}. To get at the wrapped IO, use `__getobj__`.
  #
  # @since 2.1.0
  WITHHELD = [:to_io, :to_path].freeze

  def respond_to_missing?(name, include_private = false)
    !WITHHELD.include?(name) && super
  end

  # Keyword arguments reach the wrapped IO through here, as they do in Delegator's own
  ruby2_keywords def method_missing(name, *args, &blk)
    raise NoMethodError.new("ProgressiveIO does not hand out the IO it wraps, so that reads go through it - use __getobj__", name) if WITHHELD.include?(name)
    super
  end

  # Seeks to a position in the IO stream.
  #
  # @param a [Array] Arguments to pass to the underlying IO#seek method
  # @return [Integer] The new position
  # @see IO#seek
  def seek(*a)
    super(*a)
  end

  # Sets the position in the IO stream.
  #
  # @param p [Integer] The new position
  # @return [Integer] The new position
  # @see IO#pos=
  def pos=(p)
    super(p).tap { notify_read }
  end

  private

    # Calls the progress block with the current position. A stream without one (a pipe, a
    # socket) raises when asked for it, and from then on the bytes read so far stand in.
    #
    # @param data [String, Integer, Array, nil] What the read returned
    # @param chomped [Boolean] Whether the read took line separators off what it returned, which
    #   still came off the stream
    # @return [void]
    def notify_read(data = nil, chomped: false)
      position = positioned? ? pos : (@consumed += bytes_in(data, chomped))
      @progress_block.call(position) if @progress_block
    end

    def positioned?
      return @positioned unless @positioned.nil?
      pos
      @positioned = true
    rescue Errno::ESPIPE, IOError
      @positioned = false
    end

    def unread(data)
      @consumed = [@consumed - bytes_in(data, false), 0].max unless positioned?
    end

    # With chomp, a line came off the stream with a separator that is not in it anymore. Which
    # one is not known here; "\n" is the default and by far the likeliest, and the last line
    # of a stream may have had none - so on a stream without a position, a chomped count can
    # be a byte off per line, and the last one high by one
    def bytes_in(data, chomped)
      case data
      when String then data.bytesize + (chomped ? 1 : 0)
      when Integer then 1
      when Array then data.sum { |item| bytes_in(item, chomped) }
      else 0
      end
    end

    def codepoint_string(codepoint)
      codepoint.chr(external_encoding || Encoding::UTF_8)
    rescue RangeError, EncodingError, NoMethodError
      "?"
    end
end
