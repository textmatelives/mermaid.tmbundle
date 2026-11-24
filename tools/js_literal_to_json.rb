#!/usr/bin/env ruby
# Reads starry-night grammar modules (`const grammar = {...}; export default
# grammar`) as text and converts the object literal to JSON without executing
# any of it. The literals are machine-printed: unquoted or quoted keys,
# single- or double-quoted strings with backslash escapes, numbers, booleans,
# arrays and objects. Anything else is an error.
require "json"

class JSLiteral
  class Error < StandardError; end

  def initialize(src)
    @s = src
    @i = 0
  end

  def parse
    v = value
    ws
    raise Error, "trailing input at #{@i}" unless @i == @s.length
    v
  end

  private

  def ws
    @i += 1 while @i < @s.length && @s[@i] =~ /\s/
  end

  def peek
    ws
    @s[@i]
  end

  def expect(ch)
    raise Error, "expected #{ch.inspect} at #{@i}, got #{@s[@i].inspect}" unless peek == ch
    @i += 1
  end

  def value
    case peek
    when "{" then object
    when "[" then array
    when "'", '"' then string
    when /[-0-9]/ then number
    when "t", "f", "n" then literal
    else raise Error, "unexpected #{@s[@i].inspect} at #{@i}"
    end
  end

  def object
    expect("{")
    h = {}
    loop do
      break if peek == "}"
      k = key
      expect(":")
      h[k] = value
      break unless peek == ","
      @i += 1
    end
    expect("}")
    h
  end

  def key
    c = peek
    return string if c == "'" || c == '"'
    m = @s[@i..-1].match(/\A[A-Za-z0-9_$]+/) or raise Error, "bad key at #{@i}"
    @i += m[0].length
    m[0]
  end

  def array
    expect("[")
    a = []
    loop do
      break if peek == "]"
      a << value
      break unless peek == ","
      @i += 1
    end
    expect("]")
    a
  end

  ESCAPES = { "n" => "\n", "t" => "\t", "r" => "\r", "b" => "\b", "f" => "\f", "v" => "\v", "0" => "\0" }.freeze

  def string
    q = peek
    @i += 1
    out = +""
    while (c = @s[@i]) != q
      raise Error, "unterminated string" if c.nil?
      if c == "\\"
        e = @s[@i + 1]
        if e == "u"
          out << [@s[@i + 2, 4].hex].pack("U")
          @i += 6
        elsif e == "x"
          out << @s[@i + 2, 2].hex.chr
          @i += 4
        else
          out << (ESCAPES[e] || e)
          @i += 2
        end
      else
        out << c
        @i += 1
      end
    end
    @i += 1
    out
  end

  def number
    m = @s[@i..-1].match(/\A-?\d+(\.\d+)?/)
    @i += m[0].length
    m[1] ? m[0].to_f : m[0].to_i
  end

  def literal
    %w[true false null].each do |word|
      if @s[@i, word.length] == word
        @i += word.length
        return { "true" => true, "false" => false, "null" => nil }[word]
      end
    end
    raise Error, "bad literal at #{@i}"
  end
end

src_dir, out_dir = ARGV
Dir[File.join(src_dir, "*.js")].sort.each do |path|
  text = File.read(path)
  start = text.index("const grammar = ") or abort("#{path}: no grammar literal")
  stop = text.rindex("\nexport default grammar") or abort("#{path}: no export")
  literal = text[(start + "const grammar = ".length)...stop].strip
  literal = literal.chomp(";")
  grammar = JSLiteral.new(literal).parse
  File.write(File.join(out_dir, File.basename(path, ".js") + ".json"), JSON.pretty_generate(grammar))
  puts "#{File.basename(path)}: ok"
end
