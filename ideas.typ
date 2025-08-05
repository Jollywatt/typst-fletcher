#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#import "marks.typ"

#cetz.canvas({
  import cetz.draw

  flexigrid(
    name: "a",
    debug: "grid",
    gutter: 1,
  {
    let a = node((2,0), $"up"(bold(x))^2$, inset: 5pt, name: "bi")
    a
    node((0,1), [Hello\ World], inset: 5pt, name: "hi")
    draw.circle("bi.north-west", radius: 0.2, stroke: yellow)
    edge((0,1), "->", (2,0), snap-to: (auto, auto))
    marks.with-marks(draw.line("bi.north", (2,2)), "<>->")
  })
    // edge((0,3), "latex-o-|>", (3,3))

})
 
