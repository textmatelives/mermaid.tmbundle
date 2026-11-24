#!/usr/bin/env ruby
# Builds Mermaid.tmbundle/Syntaxes from the JSON grammars: one tmLanguage per
# scope, the base grammar (source.mermaid) visible with its file types, the
# diagram sub-grammars hidden from the language menu.
require "json"
require "fileutils"
require "securerandom"

json_dir, bundle_dir = ARGV
syntaxes = File.join(bundle_dir, "Syntaxes")
FileUtils.mkdir_p(syntaxes)

def display_name(scope)
  tail = scope.sub("source.mermaid", "").sub(/\A\./, "")
  return "Mermaid" if tail.empty?
  "Mermaid (" + tail.split("-").map(&:capitalize).join(" ").sub("C4c", "C4C").sub("Er ", "ER ").sub("Zenuml", "ZenUML") + ")"
end

Dir[File.join(json_dir, "*.json")].sort.each do |path|
  g = JSON.parse(File.read(path))
  scope = g.fetch("scopeName")
  base = scope == "source.mermaid"
  out = {
    "name"       => display_name(scope),
    "scopeName"  => scope,
    "uuid"       => SecureRandom.uuid.upcase,
    "patterns"   => g.fetch("patterns"),
    "repository" => g.fetch("repository", {}),
  }
  out["fileTypes"] = g.fetch("extensions").map { |e| e.sub(/\A\./, "") } if base
  out["hideFromUser"] = true unless base
  json_path = File.join(syntaxes, out["name"] + ".json")
  File.write(json_path, JSON.generate(out))
  plist_path = File.join(syntaxes, out["name"] + ".tmLanguage")
  system("plutil", "-convert", "xml1", json_path, "-o", plist_path) or abort("plutil failed for #{scope}")
  File.delete(json_path)
  puts "#{out['name']}.tmLanguage <- #{scope}"
end
