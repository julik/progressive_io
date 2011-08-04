require "delegate"

class ProgressiveIO < DelegateClass(IO)
  VERSION = '1.0.0'
  
  # Get or set the total size of the contained IO. If the passed IO is a File object 
  # the size will be preset automatically
  attr_accessor :total_size
  attr_accessor :progress_block
  
  # The constructor accepts an IO object and the block that will be called when the IO is read.
  # If the passed IO is a File-like object that responds to #stat then the size will be computed
  # automatically
  def initialize(with_io, &blk)
    __setobj__(with_io)
    @total_size = with_io.stat.size if with_io.respond_to?(:stat)
    @progress_block = blk.to_proc if blk
  end
  
  # Report offset at each line
  def each(sep_string = $/, &blk)
    # Report offset at each call of the iterator
    result = super(sep_string) do | line |
      yield(line)
      notify_read
    end
  end
  alias_method :each_line, :each
  
  def each_byte(&blk)
    # Report offset at each call of the iterator
    super { |b| yield(b); notify_read }
  end
  
  def getc
    returning(super) { notify_read }
  end
  
  def gets
    returning(super) { notify_read }
  end
  
  def read(*a)
    returning(super) { notify_read }
  end
  
  def readbytes(*a)
    returning(super) { notify_read }
  end
  
  def readchar
    returning(super) { notify_read }
  end
  
  def readline(*a)
    returning(super) { notify_read }
  end
  
  def readlines(*a)
    returning(super) { notify_read }
  end
  
  def seek(*a)
    returning(super) { notify_read }
  end
  
  def ungetc(*a)
    returning(super) { notify_read }
  end 
  
  def pos=(p)
    returning(super) { notify_read }
  end
  
  private
    # The "returning" idiom copied from ActiveSupport. We know that modern Rubies have
    # Object#tap but why mandate newer Rubies for something as small as this?
    def returning(r)
      yield(r); r
    end
    
    # This method will be called when something is read
    def notify_read
      @progress_block.call(pos, @total_size) if @progress_block
    end
end
