#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram({
  node((0,0), [A])
  edge("r", [body], label-sep: 2pt)
  node((1,0), [A])
  edge("r", label: (body: [body], sep: 2pt))
  node((2,0), [A])
  edge("r", label: (
    (body: [body 1], side: top),
    (body: [body 2], side: bottom),
  ), label-sep: 2pt)
})

#pagebreak()

Default to north of line
#cetz.canvas({
  for i in range(12) {
    edge((0,0), "->", (360deg/12*i, 3), $f$)
  }
})

#pagebreak()

Default to north of line
#cetz.canvas({
  for i in range(8) {
    edge((0,0), "->", (360deg/8*i, 2), `top`, label-side: top+right, label-sep: 0)
  }
})

#pagebreak()

Default to outer side of curve
#diagram(spacing: 4, {
  edge((0,0), (1,0), bend: +40deg, `above`)
  edge((0,0), (1,0), bend: -40deg, `below`)
})

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