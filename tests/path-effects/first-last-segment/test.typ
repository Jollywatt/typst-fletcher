#set page(width: auto, height: auto, margin: 1em)
#import "/src/deps.typ": cetz
#import "/src/paths.typ"

Initial/final segment extraction

#cetz.canvas({
  import cetz.draw: *
  let objs = (
    line((0,1), (1,0), (2,1), (3,0)),
    arc-through((0,1), (2,0), (3,1)),
    merge-path({
      line((0,0), (1,1), (2,1))
      bezier((2,1), (3,0), (2,0))
      bezier((3,0), (4,1), (4,3), (1,-1))
    })
  )

  for obj in objs {
    obj
    paths.draw-only-first-path-segment(obj, stroke: green)
    paths.draw-only-last-path-segment(obj, stroke: red)
    translate(y: -2)
  }
})
