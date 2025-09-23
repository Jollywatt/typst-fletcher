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

#figure(diagram(debug: "", gutter: 1, {
  import cetz.draw: *

  node((-1,-1), $ bullet $)
  node((0,0), $G$, <G>)
  edge("l,d", "..>")
  node((0,-1), $G slash ker(f)$, <ker>)
  edge(<G>, "->", name: <e>, bend: 5pt)
  node((1,0), $im(f)$, <im>)
  edge(<im>, "==>", <ker>, from: -90deg, to: 45deg)
  edge(<G>, "->>", <ker>)
  edge(<im>, (rel: (1,0)), (rel: (0,-1)), (rel: (-2,0)), "=>")

}), caption: [
  Various edge kinds.
])
