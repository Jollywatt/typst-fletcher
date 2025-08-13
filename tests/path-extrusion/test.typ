#set page(width: auto, height: auto, margin: 1em)
#import "/src/deps.typ": cetz
#import "/src/paths.typ"
#import "/src/exports.typ": flexigrid, node

#cetz.canvas({
  paths.extrude(cetz.draw.line((0,0), (3,0)), (0,2,4))
  paths.extrude(cetz.draw.line((0,-1), (1,-2), (2,-1), (3,-2)), (-5,0,+5))
  paths.extrude(cetz.draw.rect((0,-3), (3,-4)), range(0,-12,step: -2))
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
  paths.extrude(l, range(-7, 8, step: 2), stroke: blue + 1pt)
})
