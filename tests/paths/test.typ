#set page(width: auto, height: auto, margin: 1em)
#import "/src/deps.typ": cetz
#import "/src/paths.typ"
#import "/src/exports.typ": flexigrid, node


Linear extrusion

#cetz.canvas({
  paths.extrude-and-shorten(cetz.draw.line((0,0), (3,0)), extrude: (0,2,4))
  paths.extrude-and-shorten(cetz.draw.line((0,-1), (1,-2), (2,-1), (3,-2)), extrude: (-5,0,+5))
  paths.extrude-and-shorten(cetz.draw.rect((0,-3), (3,-4)), extrude: range(0,-12,step: -2))
})

#pagebreak()


Curved extrusion

#cetz.canvas({
  import cetz.draw

  let arc = draw.arc-through((0,0), (1,0), (0,1))

  paths.extrude-and-shorten(arc, extrude: (-6, 0, +6))

  draw.translate(y: -2)

  let arc = draw.merge-path({
    arc
    draw.translate(x: 2)
    draw.scale(x: -1)
    arc
  })
  paths.extrude-and-shorten(arc, extrude: (-2, 0, +2))
})

#pagebreak()


#cetz.canvas({
  import cetz.draw

  let l = draw.merge-path({
    draw.line((1,2), (2,2), (2,3), (3,2), (4,2))
    draw.arc-through((4,3), (4,5), (5,4))
    draw.bezier((5,1), (1,1), (4,0), (3,2))
  }, close: true)
  l
  paths.extrude-and-shorten(l, extrude: range(-7, 8, step: 2), stroke: blue + 1pt)
})


#pagebreak()

Path shortening

#cetz.canvas({
  let objs = (
    cetz.draw.line((0,0), (3,0)),
    cetz.draw.line((0,-1), (1,-2), (2,-1), (3,-2)),
    cetz.draw.arc-through((0,-3), (2,-4), (3,-3)),
  )

  for obj in objs {
    paths.extrude-and-shorten(obj, extrude: (+4, +2, 0, -2, -4), shorten-start: (0, 2, 5, 2, 0), shorten-end: (4, 2, 0, 2, 4))
  }
})
