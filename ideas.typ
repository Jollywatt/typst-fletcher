#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#cetz.canvas({
  import cetz.draw

  flexigrid({
    node((0,0), [Hello], inset: 0pt, name: "hi")
    node((2,0), [World], inset: 5pt, name: "bi")
    cetz.draw.circle((1,1), radius: 0.3, stroke: yellow)
    draw.line("bi.north", (2,2))
  },
    name: "a",
    debug: true,
    gutter: 1,
  )

})