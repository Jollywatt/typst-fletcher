#import "../common.typ": *
#show: style


= Tutorial

Import fletcher with:

#raw(block: true, lang: "typ", "#import \"@preview/fletcher:" + VERSION + "\" as fletcher: diagram, node, edge")

Diagrams are laid out on a _flexible coordinate grid_, visible when the @flexigrid.debug option of @diagram is on.
When a node is placed, the rows and columns grow to accommodate the node's size, like a table.

#example(```typ
#let c = (orange, red, green, blue).map(x => x.lighten(50%))
#diagram(
  debug: 3,
  spacing: 10pt,
  node-corner-radius: 3pt,
  node((0,0), [a], fill: c.at(0), width: 1, height: 1),
  node((1,0), [b], fill: c.at(1), width: .5, height: .5),
  node((1,1), [c], fill: c.at(2), width: 2, height: .5),
  node((0,2), [d], fill: c.at(3), width: .5, height: 1),
)
```)