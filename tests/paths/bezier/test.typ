#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ": paths, cetz

#cetz.canvas({
  import cetz.draw: *

  let obj = merge-path({
    line((1,2), (2,2), (2,3), (3,2), (3.5,2))
    arc-through((4,3), (4,5), (5,4))
    line((4.5,4), (4.5,2))
    bezier((5,1), (1,1), (4,0), (3,2))
  }, close: true, stroke: luma(80%))

  obj

  (
    paths.path-effect(obj, stroke: blue, corner: "round", corner-radius: 0.2),
    paths.path-effect(obj, stroke: blue, corner: "round", corner-radius: 0.1, extrude: (+4, +2, 0, -2, -4)),
    paths.path-effect(obj, stroke: blue, extrude: (+4, +2, 0, -2, -4)),
    paths.path-effect(obj, stroke: blue, extrude: (+4, +2, 0, -2, -4), miter-limit: 1.5),
  ).map(transformed => {
    obj
    transformed
    translate(y: -5)
  }).join()  

})

#pagebreak()

#cetz.canvas({
  import cetz.draw: *

  let obj = merge-path({
    arc-through((0,0), (1,2), (2,0))
    arc-through((2,0), (1,0.25), (0,0))
  }, close: true, stroke: luma(80%))

  (
    arguments(corner: "round", corner-radius: 0.2),
    arguments(corner: "round", corner-radius: 0.1, extrude: (+4pt, +2pt, 0, -2pt, -4pt)),
    arguments(extrude: (+4pt, +2pt, 0, -2pt, -4pt)),
    arguments(extrude: (+4pt, +2pt, 0, -2pt, -4pt), miter-limit: 0),
  ).map(args => {
    obj
    paths.path-effect(obj, stroke: red + 0.5pt, ..args)
    translate(y: -2.5)
  }).join()  

})
