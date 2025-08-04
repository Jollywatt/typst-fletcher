#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#import "marks.typ"

#cetz.canvas({
  import cetz.draw

  flexigrid(
    name: "a",
    debug: false,
    gutter: 1,
  {
    node((2,0), $"up"(bold(x))^2$, inset: 5pt, name: "bi")
    node((0,0), [Hello\ World], inset: 5pt, name: "hi")
    draw.circle("bi.north-west", radius: 0.2, stroke: yellow)
    edge((0,3), "latex-o-|>", (3,3))
    marks.with-marks(draw.line("bi.north", (2,2)), "<>->")
  })

})
