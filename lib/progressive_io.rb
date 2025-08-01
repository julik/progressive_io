require "forwardable"

class ProgressiveIO
  extend Forwardable
  

  
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
    @io.each(sep_string) do | line |
      yield(line).tap { notify_read }
    end
  end
  alias_method :each_line, :each
  
  def each_byte(&blk)
    # Report offset at each call of the iterator
    @io.each_byte { |b| yield(b).tap { notify_read } }
  end
  
  def getc
    inner(:getc)
  end
  
  def gets(*args)
    inner(:gets, *args)
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
      r = @io.respond_to?(:public_send) ? @io.public_send(m, *args) : @io.send(m, *args)
      r.tap { notify_read }
    end
    
    # This method will be called when something is read
    def notify_read
      @progress_block.call(@io.pos, @total_size) if @progress_block
    end
end
