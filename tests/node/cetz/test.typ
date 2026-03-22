#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

Nodes should render directly to a CeTZ canvas.

#cetz.canvas({
  import cetz.draw: *
  node((0,0), [Hello], stroke: 0.5pt)
  set-style(node: (stroke: 2pt + blue, outset: 1pt,))
  node((2,0), [World])
  set-style(node: (shape: circle, fill: blue.transparentize(60%)))
  node((1,-1), [f])
  edge((0,0), "<->", (2,0))
  edge((2,0), (2,-1), (1,-1), "==")
})