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

#pagebreak()

#cetz.canvas({
  import cetz.draw: *

  set-style(line: (stroke: 0.5pt))

  let snap-to(edge, src, tgt, stroke: black) = get-ctx(ctx => {
    let drawable-to-path(it) = cetz.process.element(ctx, it.first()).drawables.first()
    let d0 = drawable-to-path(edge)
    let d1 = drawable-to-path(src)
    let d2 = drawable-to-path(tgt)
    d0 = paths.intersection.trim-drawable(d0, d1, from-end: true, index: -1)
    d0 = paths.intersection.trim-drawable(d0, d2, index: -1)
    d0.stroke = stroke
    (ctx => (
      ctx: ctx,
      drawables: d0
    ),)
  })

  let o1 = circle((0,0), radius: 0.5)
  let o2 = rect((2,1), (4,3))
  let edge = line((0,0), (2,0), (3,2))
  o1
  o2
  edge
  snap-to(edge, o1, o2, stroke: red)

  let edge = line((0,0), (1,1), (0,2), (-1,1), (0,0))
  edge
  snap-to(edge, o1, o1, stroke: blue)


  
})