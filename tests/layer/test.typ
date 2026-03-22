#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram(
  node((0,0), fill: red, [Foreground]),
  node((0,0), fill: blue, [Back#v(1em)ground], layer: -1),
  edge((0,0), (2,0), layer: 1, [Over]),
  edge((1,-1), (1,1), stroke: 5pt + yellow, text(yellow)[Under], label-side: right, label-pos: 40%),
)