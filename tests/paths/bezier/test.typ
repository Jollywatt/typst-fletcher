#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ": paths, cetz

#cetz.canvas({
  import cetz.draw: *

  let obj = merge-path({
    line((1,2), (2,2), (2,3), (3,2), (3.5,2))
    arc-through((4,3), (4,5), (5,4))
    line((4.5,4), (4.5,2))
    bezier((5,1), (1,1), (4,0), (3,2))
  }, close: false, stroke: luma(80%))

  obj

  (
    paths.path-effect(obj, stroke: blue, corner: "round", corner-radius: 0.2),
    paths.path-effect(obj, stroke: blue, extrude: (+4, +2, 0, -2, -4)),
    paths.path-effect(obj, stroke: blue, corner: "round", corner-radius: 0.1, extrude: (+4, +2, 0, -2, -4)),
    paths.path-effect(obj, stroke: blue +1pt, corner: "bevel", extrude: (+4, +2, 0, -2, -4).map(a => a*1pt)),
  ).map(transformed => {
    obj
    transformed
    translate(y: -5)
  }).join()  

})
