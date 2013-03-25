require "forwardable"

class ProgressiveIO
  extend Forwardable
  
  IO_METHODS = (IO.instance_methods - Object.instance_methods - Enumerable.instance_methods).map{|e| e.to_sym }
  def_delegators :io, *IO_METHODS
  
  VERSION = '2.0.0'
  
  # Get or set the total size of the contained IO. If the passed IO is a File object 
  # the size will be preset automatically
  attr_accessor :total_size
  attr_accessor :progress_block
  
  # The constructor accepts an IO object and the block that will be called when the IO is read.
  # If the passed IO is a File-like object that responds to #stat then the size will be computed
  # automatically
  def initialize(with_io, &blk)
    @io = with_io
    @total_size = with_io.stat.size if with_io.respond_to?(:stat)
    @progress_block = blk.to_proc if blk
  end
  
  # Report offset at each line
  def each(sep_string = $/, &blk)
    # Report offset at each call of the iterator
    result = @io.each(sep_string) do | line |
      yield(line)
      notify_read
    end
  end
  alias_method :each_line, :each
  
  def each_byte(&blk)
    # Report offset at each call of the iterator
    @io.each_byte { |b| yield(b); notify_read }
  end
  
  def getc
    inner(:getc)
  end
  
  def gets
    inner(:gets)
  end
  
  def read(*a)
    inner(:read, *a)
  end
  
  def readbytes(*a)
    inner(:readbytes, *a)
  end
  
  def readchar
    inner(:readchar)
  end
  
  def readline(*a)
    inner(:readline, *a)
  end
  
  def readlines(*a)
    inner(:readlines, *a)
  end
  
  def seek(*a)
    inner(:seek, *a)
  end
  
# def ungetc(*a)
#   inner(:ungetc, a)
# end 
  
  def pos=(p)
    inner(:pos=, p)
  end
  
  private
    
    def io
      @io
    end
    
    def inner(m, *args)
      $stderr.puts args.inspect
      r = @io.respond_to?(:public_send) ? @io.public_send(m, *args) : @io.send(m, *args)
      returning(r) { notify_read }
    end
    # The "returning" idiom copied from ActiveSupport. We know that modern Rubies have
    # Object#tap but why mandate newer Rubies for something as small as this?
    def returning(r)
      yield(r); r
    end
    
    # This method will be called when something is read
    def notify_read
      @progress_block.call(@io.pos, @total_size) if @progress_block
    end
end
