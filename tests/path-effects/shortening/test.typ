#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ": paths, cetz

#import cetz.draw: *
#(
  line((0,0), (1,1), (2,0), (3,0)),
  catmull((0,0), (1,1), (2,0), (3,0)),
  arc((1.5,0), start: -45deg, delta: 270deg, radius: (1.5, 0.5), anchor: "center")
).map(obj => cetz.canvas({
  obj
  paths.path-effect(
    obj,
    extrude: (4, 2, 0, -2, -4),
    shorten-start: (4, 2, 0, 2, 4),
    shorten-end: (0, 2, 4, 2, 0),
    stroke: red.transparentize(50%),
  )
})).join()
