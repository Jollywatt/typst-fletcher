#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram(edge((0,0), (1,0), label: (
  (body: $0$, pos: 0),
  (body: $1/2$, pos: 0.5),
  (body: $1$, pos: 1),
)))

#pagebreak()

Segment placement
#diagram({
  edge((0,0), (1,0), (1,2), (2,1), (2,0), (3,0), "->", label: (
    (body: `1`, pos: 0.5),
    (body: `2`, pos: 1.5),
    (body: `3`, pos: 2.5),
    (body: `4`, pos: 3.5),
    (body: `5`, pos: 4.5),
  ))
})