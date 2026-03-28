/// [max-delta: 80]


#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  import cetz.draw: *
  {
    edge((0,0), "->", (1,0))
    edge((0,0), "->", (1,0), bend: 30deg)
    edge((0,0), "->", (1,0), to: 90deg)
    edge((0,0), "->", (1,0), from: 90deg, to: -90deg)
    edge((0,0), "->", (1,0), through: (.4,-.5))
  }.intersperse(translate(y: -.8)).flatten()
})


#pagebreak()

#figure(diagram(debug: "", spacing: 1, {
  import cetz.draw: *

  node((-1,-1), $ bullet $)
  node((0,0), $G$, <G>)
  edge("l,d", "..>")
  node((0,-1), $G slash ker(f)$, <ker>)
  edge(<G>, "->", name: <e>, bend: 5pt)
  node((1,0), $im(f)$, <im>)
  edge(<im>, "==>", <ker>, from: (-90deg, 1.5), to: (45deg, 2))
  edge(<G>, "->>", <ker>)
  edge(<im>, (rel: (1,0)), (rel: (0,-1)), (rel: (-2,0)), "=>")

}), caption: [
  Various edge kinds.
])

#pagebreak()

Edge loops

#diagram(
  node-fill: green,
  node-stroke: 0.1em + black,
  node((0,0), [0], name: "0", extrude: (0,2), outset: 2pt),
  node((0,1), [1], name: "1"),
  node((1,0), [2], name: "2"),
  node((2,0), [3], name: "3"),
  node((1,1), [4], name: "4"),
  node((2,1), [5], name: "5"),

  edge(<0>, "->", <1>, $b$),
  edge(<0>, <1>, $b$, "->"),
  edge(<0>, <2>, $a$, "->"),
  edge(<1>, <1>, $a$, "->", loop-angle: top),
  edge(<1>, <4>, $a$, "->"),
  edge(<2>, <3>, $a$, "->"),
  edge(<2>, <4>, $b$, "->"),
  edge(<3>, <2>, $b$, "->", label-side: bottom),
  edge(<3>, <3>, $a$, "->", loop-angle: right),
  edge(<4>, <0>, $a$, "->"),
  edge(<4>, <5>, $b$, "->"),
  edge(<5>, <4>, $a$, "->", label-side: bottom),
  edge(<5>, <5>, $b$, "->", loop-angle: right),
)
