require "minitest/autorun"
require_relative "../lib/progressive_io"
require "flexmock"
require "flexmock/minitest"
require "stringio"

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
    
    if RUBY_VERSION < "1.9"
      assert_equal 49, io.getc
    else
      assert_equal "1", io.getc
    end
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
  
  def test_seek
    io = e("Mary\nHad\nA little\nLamb")
    io.progress_block = lambda do | offset |
      assert_equal 6, offset
    end
    io.seek(6)
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