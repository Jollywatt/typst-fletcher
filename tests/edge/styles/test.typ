#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram(
  import cetz.draw: *,
  edge-stroke: blue,
  (
    edge("-->"),
    edge("->", stroke: yellow),
    edge("->", stroke: 1pt, dash: "dotted"),
    edge("=>", stroke: black),
    edge("<...>"),
    edge("<..>"),
    edge("<. .>"),
    edge("<--->"),
    edge("<-->"),
    edge("<- ->"),
  ).intersperse(translate(y: -0.5))
)