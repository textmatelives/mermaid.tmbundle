# Run with: ruby Tests/grammar_test.rb
# Structural checks on the generated grammars: they lint, every cross-grammar
# include resolves inside the bundle, scopes are unique, and only the base
# grammar is user-visible.
require "minitest/autorun"
require "json"
require "open3"

class GrammarTest < Minitest::Test
  SYNTAXES = File.expand_path("../Syntaxes", __dir__)
  FILES    = Dir[File.join(SYNTAXES, "*.tmLanguage")].sort

  def grammars
    @grammars ||= FILES.to_h do |file|
      json, status = Open3.capture2("plutil", "-convert", "json", "-o", "-", file)
      assert status.success?, "plutil could not read #{file}"
      [file, JSON.parse(json)]
    end
  end

  def includes(node, found = [])
    case node
    when Hash
      found << node["include"] if node["include"].is_a?(String)
      node.each_value { |v| includes(v, found) }
    when Array
      node.each { |v| includes(v, found) }
    end
    found
  end

  def test_there_is_a_base_grammar_and_sixteen_diagram_grammars
    assert_equal 17, FILES.length
    scopes = grammars.values.map { |g| g["scopeName"] }
    assert_includes scopes, "source.mermaid"
    assert_equal scopes.uniq.length, scopes.length, "scope names must be unique"
    assert scopes.all? { |s| s.start_with?("source.mermaid") }
  end

  def test_every_grammar_lints
    FILES.each do |file|
      _out, status = Open3.capture2("plutil", "-lint", file)
      assert status.success?, "#{file} does not lint"
    end
  end

  # Upstream rules that point at a repository entry which does not exist. They
  # are harmless (TextMate skips an include it cannot resolve) and listed here
  # so an upstream fix or a new one shows up as a test change.
  KNOWN_DANGLING = [
    "Mermaid (C4C Diagram).tmLanguage -> source.mermaid.user-journey#title",
  ].freeze

  def test_mermaid_includes_resolve_inside_the_bundle
    by_scope = grammars.values.to_h { |g| [g["scopeName"], g] }
    dangling = []
    grammars.each do |file, grammar|
      includes(grammar).each do |ref|
        scope, anchor = ref.split("#", 2)
        next unless scope.start_with?("source.mermaid")
        target = by_scope[scope]
        refute_nil target, "#{File.basename(file)} includes #{ref}, and #{scope} is not in the bundle"
        dangling << "#{File.basename(file)} -> #{ref}" if anchor && !target["repository"].key?(anchor)
      end
    end
    assert_equal KNOWN_DANGLING, dangling.uniq.sort
  end

  def test_only_the_base_grammar_is_visible_and_owns_the_file_types
    grammars.each_value do |grammar|
      if grammar["scopeName"] == "source.mermaid"
        assert_equal "Mermaid", grammar["name"]
        assert_equal %w[mmd mermaid], grammar["fileTypes"]
        refute grammar["hideFromUser"]
      else
        assert grammar["hideFromUser"], "#{grammar['scopeName']} should be hidden from the language menu"
        assert_nil grammar["fileTypes"]
        assert_match(/\AMermaid \(.+\)\z/, grammar["name"])
      end
    end
  end

  def test_the_base_grammar_reaches_every_diagram_grammar
    base = grammars.values.find { |g| g["scopeName"] == "source.mermaid" }
    reached = includes(base).select { |ref| ref.start_with?("source.mermaid.") && !ref.include?("#") }.uniq.sort
    others  = grammars.values.map { |g| g["scopeName"] }.reject { |s| s == "source.mermaid" }.sort
    assert_equal others, reached
  end
end
