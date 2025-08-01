# frozen_string_literal: true

require 'delegate'

# A wrapper class that provides progress tracking for IO operations.
# 
# This class wraps an IO object and calls a progress block whenever data is read,
# allowing you to track reading progress for operations like file uploads or downloads.
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
# @since 2.0.0
class ProgressiveIO < SimpleDelegator
  # The version of the ProgressiveIO library
  VERSION = '2.0.1'
  
  # @return [Proc, nil] The progress callback block that will be called when data is read
  #   The block receives one parameter: current position
  attr_accessor :progress_block
  
  # Creates a new ProgressiveIO wrapper around an IO object.
  # 
  # @param with_io [IO] The IO object to wrap (File, StringIO, etc.)
  # @param blk [Proc, nil] Optional block that will be called when data is read
  #   The block receives one parameter: current position
  # @yield [current_pos] The progress callback
  # @yieldparam current_pos [Integer] The current position in the IO stream
  # 
  # @example
  #   file = File.open('data.txt')
  #   progress_io = ProgressiveIO.new(file) do |pos|
  #     puts "Read #{pos} bytes"
  #   end
  def initialize(with_io, &blk)
    super(with_io)
    @progress_block = blk.to_proc if blk
  end
  
  # Iterates over the IO stream line by line, calling the progress block for each line.
  # 
  # @param sep_string [String] The line separator (defaults to $/)
  # @yield [line] Each line from the IO stream
  # @yieldparam line [String] A line from the IO stream
  # @return [Enumerator] An enumerator if no block is given
  # 
  # @example
  #   progress_io.each_line do |line|
  #     puts "Processing: #{line.chomp}"
  #   end
  def each(sep_string = $/, &blk)
    # Report offset at each call of the iterator
    super(sep_string) do |line|
      yield(line).tap { notify_read }
    end
  end
  alias_method :each_line, :each
  
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
  def each_byte(&blk)
    # Report offset at each call of the iterator
    super { |b| yield(b).tap { notify_read } }
  end
  
  # Reads a single character from the IO stream.
  # 
  # @return [String, nil] The next character or nil if at end of stream
  # @see IO#getc
  def getc
    super.tap { notify_read }
  end
  
  # Reads a line from the IO stream.
  # 
  # @param args [Array] Arguments to pass to the underlying IO#gets method
  # @return [String, nil] The next line or nil if at end of stream
  # @see IO#gets
  def gets(*args)
    super(*args).tap { notify_read }
  end
  
  # Reads data from the IO stream.
  # 
  # @param a [Array] Arguments to pass to the underlying IO#read method
  # @return [String, nil] The read data or nil if at end of stream
  # @see IO#read
  def read(*a)
    super(*a).tap { notify_read }
  end
  
  # Reads a specific number of bytes from the IO stream.
  # 
  # @param a [Array] Arguments to pass to the underlying IO#readbytes method
  # @return [String] The read bytes
  # @see IO#readbytes
  def readbytes(*a)
    super(*a).tap { notify_read }
  end
  
  # Reads a single character from the IO stream.
  # 
  # @return [String] The next character
  # @raise [EOFError] If at end of stream
  # @see IO#readchar
  def readchar
    super.tap { notify_read }
  end
  
  # Reads a line from the IO stream.
  # 
  # @param a [Array] Arguments to pass to the underlying IO#readline method
  # @return [String] The next line
  # @raise [EOFError] If at end of stream
  # @see IO#readline
  def readline(*a)
    super(*a).tap { notify_read }
  end
  
  # Reads all lines from the IO stream.
  # 
  # @param a [Array] Arguments to pass to the underlying IO#readlines method
  # @return [Array<String>] Array of lines
  # @see IO#readlines
  def readlines(*a)
    super(*a).tap { notify_read }
  end
  
  # Seeks to a position in the IO stream.
  # 
  # @param a [Array] Arguments to pass to the underlying IO#seek method
  # @return [Integer] The new position
  # @see IO#seek
  def seek(*a)
    super(*a)
  end
  
# def ungetc(*a)
#   super(*a).tap { notify_read }
# end 
  
  # Sets the position in the IO stream.
  # 
  # @param p [Integer] The new position
  # @return [Integer] The new position
  # @see IO#pos=
  def pos=(p)
    super(p).tap { notify_read }
  end
  
  private
    
    # Calls the progress block with current position.
    # This method is called whenever data is read from the IO stream.
    # 
    # @return [void]
    def notify_read
      @progress_block.call(pos) if @progress_block
    end
end
