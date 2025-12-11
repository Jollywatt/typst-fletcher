#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz, paths

#cetz.canvas({
  import cetz.draw: *
  let test-obj = line((-2,-1), (2,1), stroke: blue)
  let objs = circle((0,0)) + rect((-1,-1), (1,1))
  test-obj
  objs
  get-ctx(ctx => {
    let path = cetz.process.element(ctx, test-obj.first()).drawables.first()
    let drawables = cetz.process.many(ctx, objs).drawables
    let pts = drawables.map(d => cetz.intersection.path-path(path, d)).join()
    for pt in pts {
      pt = cetz.util.revert-transform(ctx.transform, pt)
      circle(pt, radius: 1pt, stroke: none, fill: red)
    }
  })
})