#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

// scale as an edge attribute
#diagram({
  for s in (0.2, 0.5, 1, 1.5, 2) {
    edge(">->", mark-scale: s)
    cetz.draw.translate(y: -0.5)
  }
})

#pagebreak()

// scale as a mark attribute
#diagram({
  for s in (0.2, 0.5, 1, 1.5, 2) {
    edge(marks: (none, (inherit: ">", scale: s)))
    cetz.draw.translate(y: -0.5)
  }
})

#pagebreak()

https://github.com/Jollywatt/typst-fletcher/issues/144

#diagram({
  cetz.draw.set-style(edge: (stroke: black.transparentize(50%)))
  for m in (30%, 50%, 100%) {
    edge((0, 0), (2, 0), "-|>", stroke: (thickness: 3pt, cap: "square"), mark-scale: m)
    cetz.draw.translate(x: 3)
  }
})


#pagebreak()

#diagram(
  mark-scale: 200%,
  edge("-|>"),
)

#diagram(
  cetz.draw.set-style(edge: (mark-scale: 200%)),
  edge("-|>"),
)