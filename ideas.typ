#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#import "marks.typ"

#cetz.canvas({
  import cetz.draw

  flexigrid({
    node((0,0), [Hello\ World], inset: 5pt, name: "hi")
    node((2,0), [_fletcher_], inset: 5pt, name: "bi")
    cetz.draw.circle("bi.north-west", radius: 0.2, stroke: yellow)
    marks.with-marks(draw.line("bi.north", (2,2)), ">->")
  },
    name: "a",
    debug: "grid",
    gutter: 1,
  )

})