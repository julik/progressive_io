require "minitest/autorun"
require_relative "../lib/progressive_io"
require "flexmock"
require "flexmock/minitest"
require "stringio"
require "tempfile"

class TestProgressiveIO < Minitest::Test
  
  def e(s)
    
    # Make a mock File object from a string
    io = StringIO.new(s)
    mock_stat = flexmock(:size => s.length)
    flexmock(io).should_receive(:stat).and_return(mock_stat)
    
    ProgressiveIO.new(io)
  end
  
  def test_each
    io, messages = e("Mary\nHad\nA little\nLamb"), []
    
    io.progress_block = lambda do | offset |
      messages.push([offset])
    end
    
    lines = []
    io.each {|line|  lines.push(line) }
    assert_equal ["Mary\n", "Had\n", "A little\n", "Lamb"], lines
    assert_equal [[5], [9], [18], [22]], messages
  end
  
  def test_each_returns_enumerator_without_block
    io, messages = e("Mary\nHad\nA little\nLamb"), []
    
    io.progress_block = lambda do | offset |
      messages.push([offset])
    end
    
    enum = io.each
    assert_kind_of Enumerator, enum
    
    # Enumerator should yield lines and still trigger progress callbacks
    lines = enum.to_a
    assert_equal ["Mary\n", "Had\n", "A little\n", "Lamb"], lines
    assert_equal [[5], [9], [18], [22]], messages
  end
  
  def test_each_line_returns_enumerator_without_block
    io, messages = e("Mary\nHad\nA little\nLamb"), []
    
    io.progress_block = lambda do | offset |
      messages.push([offset])
    end
    
    enum = io.each_line
    assert_kind_of Enumerator, enum
    
    # Enumerator should yield lines and still trigger progress callbacks
    lines = enum.to_a
    assert_equal ["Mary\n", "Had\n", "A little\n", "Lamb"], lines
    assert_equal [[5], [9], [18], [22]], messages
  end
  
  def test_each_enumerator_with_custom_separator
    io, messages = e("Mary|Had|A little|Lamb"), []
    
    io.progress_block = lambda do | offset |
      messages.push([offset])
    end
    
    enum = io.each("|")
    assert_kind_of Enumerator, enum
    
    lines = enum.to_a
    assert_equal ["Mary|", "Had|", "A little|", "Lamb"], lines
    assert_equal [[5], [9], [18], [22]], messages
  end
  
  def test_each_enumerator_chainable
    io = e("Mary\nHad\nA little\nLamb")
    
    # Should be chainable with Enumerator methods like with_index
    result = io.each.with_index.map { |line, idx| [idx, line.chomp] }
    assert_equal [[0, "Mary"], [1, "Had"], [2, "A little"], [3, "Lamb"]], result
  end
  
  def test_each_line_enumerator_references_each_line_method
    io = e("Mary\nHad\nLamb")
    
    # The enumerator returned by each_line should reference :each_line, not :each
    # This is important for proper Enumerator behavior and introspection
    each_enum = io.each
    each_line_enum = io.each_line
    
    assert_match(/:each\b/, each_enum.inspect, "each enumerator should reference :each method")
    assert_match(/:each_line\b/, each_line_enum.inspect, "each_line enumerator should reference :each_line method")
  end
  
  def test_each_byte
    io, messages = e("123"), []
    
    io.progress_block = lambda do | offset |
      messages.push([offset])
    end
    
    bytes = []
    io.each_byte{|s| bytes << s }
    assert_equal [49, 50, 51], bytes
    assert_equal [[1], [2], [3]], messages
  end
  
  def test_each_byte_returns_enumerator_without_block
    io, messages = e("123"), []
    
    io.progress_block = lambda do | offset |
      messages.push([offset])
    end
    
    enum = io.each_byte
    assert_kind_of Enumerator, enum
    
    # Enumerator should yield bytes and still trigger progress callbacks
    bytes = enum.to_a
    assert_equal [49, 50, 51], bytes
    assert_equal [[1], [2], [3]], messages
  end
  
  def test_each_byte_enumerator_chainable
    io = e("123")
    
    # Should be chainable with Enumerator methods like with_index
    result = io.each_byte.with_index.map { |byte, idx| [idx, byte] }
    assert_equal [[0, 49], [1, 50], [2, 51]], result
  end
  
  def test_getc
    io = e("123")
    io.progress_block = lambda do | offset |
      assert_equal 1, offset
    end
    if RUBY_VERSION < "1.9"
      assert_equal 49, io.getc
    else
      assert_equal "1", io.getc
    end
  end
  

  
  def test_gets
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 5, offset
    end
    assert_equal "Mary\n", io.gets
  end
  
  def test_gets_with_separator
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 4, offset
    end
    assert_equal "Mary", io.gets("y")
  end
  
  def test_gets_with_limit
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 3, offset
    end
    assert_equal "Mar", io.gets(3)
  end
  
  def test_gets_with_separator_and_limit
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 2, offset
    end
    assert_equal "Ma", io.gets("a", 2)
  end
  
  def test_read
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 15, offset
    end
    assert_equal "Mary\nHad\nA litt", io.read(15)
  end
  
  def test_readchar
    io = e("123")
    io.progress_block = lambda do | offset |
      assert_equal 1, offset
    end
    assert_equal "1", io.readchar
  end
  

  
  def test_readline
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 5, offset
    end
    assert_equal "Mary\n", io.readline
  end
  
  def test_readline_with_separator
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 4, offset
    end
    assert_equal "Mary", io.readline("y")
  end
  
  def test_readline_with_limit
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 3, offset
    end
    assert_equal "Mar", io.readline(3)
  end
  
  def test_readline_with_separator_and_limit
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 2, offset
    end
    assert_equal "Ma", io.readline("a", 2)
  end
  
  def test_readlines
    io = e("Mary\nHad\nA little\nLamb")
    m = []
    io.progress_block = lambda do | offset |
      m.push([offset])
    end
    
    assert_equal ["Mary\n", "Had\n", "A little\n", "Lamb"], io.readlines
    assert_equal [[22]], m
  end
  
  def test_readlines_with_separator
    io = e("Mary\nHad\nA little\nLamb")
    m = []
    io.progress_block = lambda do | offset |
      m.push([offset])
    end
    
    assert_equal ["Mary\nHad\nA little", "\nLamb"], io.readlines("e")
    assert_equal [[22]], m
  end
  
  def test_seek_is_not_a_read
    io, m = e("Mary\nHad\nA little\nLamb"), []
    io.progress_block = lambda { |offset| m << offset }
    io.seek(6)
    assert_empty m
    io.read(2)
    assert_equal [8], m
  end
  
#  def test_ungetc
#    io = e("Mary\nHad\nA little\nLamb")
#    m = []
#    io.progress_block = lambda do | offset |
#      m.push([offset])
#    end
#    
#    char = io.getc
#    io.ungetc("a")
#    assert_equal [[1], [0]], m
#  end
  
  def reported(io)
    [].tap { |m| io.progress_block = lambda { |offset| m << offset } }
  end

  def test_readpartial
    io = e("Mary\nHad\nA little\nLamb")
    m = reported(io)
    assert_equal "Mary", io.readpartial(4)
    assert_equal [4], m
  end

  def test_read_nonblock
    io = e("Mary\nHad\nA little\nLamb")
    m = reported(io)
    assert_equal "Mary", io.read_nonblock(4)
    assert_equal "\nHad", io.read_nonblock(4, exception: false)
    assert_equal [4, 8], m
  end

  def test_sysread
    io = e("Mary\nHad\nA little\nLamb")
    m = reported(io)
    assert_equal "Mary", io.sysread(4)
    assert_equal [4], m
  end

  def test_getbyte_and_readbyte
    io = e("123")
    m = reported(io)
    assert_equal 49, io.getbyte
    assert_equal 50, io.readbyte
    assert_equal [1, 2], m
  end

  def test_each_char
    io = e("abc")
    m = reported(io)
    assert_equal %w[a b c], io.each_char.to_a
    assert_equal [1, 2, 3], m
  end

  def test_each_codepoint
    io = e("ab")
    m = reported(io)
    assert_equal [97, 98], io.each_codepoint.to_a
    assert_equal [1, 2], m
  end

  # IO.copy_stream reads anything that is not an IO with readpartial
  def test_copy_stream_is_reported
    io = e("Mary\nHad\nA little\nLamb")
    m = reported(io)
    out = StringIO.new
    IO.copy_stream(io, out)
    assert_equal "Mary\nHad\nA little\nLamb", out.string
    assert_equal 22, m.last
  end

  # A real IO would be handed to IO.copy_stream through to_io and read past the wrapper
  def test_copy_stream_from_a_file_is_reported
    Tempfile.create("progressive") do |f|
      f.write("x" * 100_000)
      f.flush
      io = ProgressiveIO.new(File.open(f.path))
      m = reported(io)
      IO.copy_stream(io, StringIO.new)
      assert_equal 100_000, m.last
      refute io.respond_to?(:to_io)
      refute io.respond_to?(:to_path)
      assert_raises(NoMethodError) { io.to_io }
      assert_kind_of File, io.__getobj__
      io.__getobj__.close
    end
  end

  def test_keyword_arguments_are_passed_on
    io = e("Mary\nHad\nA little\nLamb")
    m = reported(io)
    assert_equal "Mary", io.gets(chomp: true)
    assert_equal "Had", io.readline(chomp: true)
    assert_equal ["A little", "Lamb"], io.readlines(chomp: true)
    assert_equal [5, 9, 22], m

    assert_equal ["Mary", "Had"], e("Mary\nHad\n").each_line(chomp: true).to_a
    lines = []
    e("Mary\nHad\n").each(chomp: true) { |line| lines << line }
    assert_equal ["Mary", "Had"], lines
  end

  # A pipe or a socket has no position to report, so what has been read so far stands in for it
  def test_streams_without_a_position_report_the_bytes_read
    r, w = IO.pipe
    w.write("Mary\nHad\nA little\nLamb")
    w.close
    io = ProgressiveIO.new(r)
    m = reported(io)
    assert_equal "Mary\n", io.gets
    assert_equal "Had", io.read(3)
    assert_equal "\n".ord, io.getbyte
    assert_equal ["A little\n", "Lamb"], io.each_line.to_a
    assert_equal [5, 8, 9, 18, 22], m
  ensure
    r.close if r
  end

  def test_bytes_pushed_back_into_a_stream_are_not_counted_twice
    r, w = IO.pipe
    w.write("Mary")
    w.close
    io = ProgressiveIO.new(r)
    m = reported(io)
    io.getc
    io.ungetc("M")
    assert_equal "Mary", io.read
    assert_equal [1, 4], m
  ensure
    r.close if r
  end

  def test_copy_stream_from_a_pipe
    r, w = IO.pipe
    # More than a pipe holds, so it has to be written while it is read
    writer = Thread.new { w.write("x" * 200_000); w.close }
    io = ProgressiveIO.new(r)
    m = reported(io)
    IO.copy_stream(io, StringIO.new)
    writer.join
    assert_equal 200_000, m.last
  ensure
    r.close if r
  end

  def test_counts_reads_made_before_a_block_was_set
    r, w = IO.pipe
    w.write("Mary\nHad\n")
    w.close
    io = ProgressiveIO.new(r)
    io.gets
    m = reported(io)
    io.gets
    assert_equal [9], m
  ensure
    r.close if r
  end

  def test_poseq
    io = e("Mary\nHad\nA little\nLamb")
    m = []
    io.progress_block = lambda do | offset |
      m << [offset]
    end
    io.pos = 2
    io.pos = 3
    io.pos = 4
    
    assert_equal [[2], [3], [4]], m
  end
end