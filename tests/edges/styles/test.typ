#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram(
  import cetz.draw: *,
  edge-stroke: blue,
  edge("-->"),
  translate(y: -0.5),
  edge("->", stroke: yellow),
  translate(y: -0.5),
  edge("->", stroke: 1pt, dash: "dotted"),
  translate(y: -0.5),
  edge("=>", stroke: black),
)