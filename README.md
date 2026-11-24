# Mermaid bundle for TextMate

Syntax highlighting for [Mermaid](https://mermaid.js.org) diagram source, in `.mmd` and `.mermaid` files and in fenced ```` ```mermaid ```` blocks of Markdown documents (through the Markdown (GitHub) bundle). The Markdown preview draws the diagrams; this bundle colours the source.

## What is in it

One grammar per diagram type, all reached from the base `source.mermaid` grammar, which also handles front matter, directives and comments:

flowchart, sequence diagram, class diagram, state diagram, ER diagram, Gantt, git graph, mindmap, pie chart, quadrant chart, requirement diagram, Sankey, timeline, user journey, C4 diagram and ZenUML.

Only "Mermaid" appears in the language menu; the diagram grammars are hidden and included by scope.

## Where the grammars come from

The grammars are John Gardner's [language-mermaid](https://github.com/Alhadis/language-mermaid) (ISC licence), taken from the TextMate-format conversion that [starry-night](https://github.com/wooorm/starry-night) distributes, and turned into tmLanguage property lists by the scripts in `tools/`. Nothing in the rules is edited by hand; to pick up upstream changes run:

```sh
tools/update-grammars
```

which fetches the current `source.mermaid*` grammars from starry-night, converts them without executing any of their code, and regenerates `Syntaxes/`. Then run the tests:

```sh
ruby Tests/grammar_test.rb
```

## Licence

ISC, see `LICENSE.txt`. The grammar rules are copyright John Gardner; the bundle packaging is copyright the TextMate Lives contributors.
