#import "../common.typ": *
#show: style.with(preview-mdx: false)

= Tutorial

Import fletcher with:

#raw(block: true, lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: diagram, node, edge")

Diagrams are laid out on a _flexible coordinate grid_, visible when the @flexigrid.debug option of @diagram is on.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.

#example(```typ
#diagram(
  debug: "grid",
  node((0,0), stroke: yellow, [Wide node]),
  node((1,0), fill: green, [A\ tall\ node]),
  node((0,1), fill: red, emph[top left], align: top + left),
  node((1,1), fill: blue, text(white, $ a/b $)),
)
```)