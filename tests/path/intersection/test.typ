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

#pagebreak()

Test that intersection functions return points \
consistent with the segment index/path parameter

#cetz.canvas({
  import cetz.draw: *
  set-transform(cetz.matrix.ident(4))


  let show-intersections(o1, o2) = get-ctx(ctx => {
    o1
    o2
    let drawable-to-path(it) = cetz.process.element(ctx, it.first()).drawables.first()

    let d1 = drawable-to-path(o1)
    let d2 = drawable-to-path(o2)

    let points = fletcher.paths.intersection.path-path(d2, d1)

    for (pt, (subpath-i, segment-i, t)) in points {
      let (pt2, x-vel, x-accel) = paths.point-on-path(ctx, d1.segments, segment: segment-i + t)

      let (pt, pt2) = cetz.util.revert-transform(ctx.transform, pt, pt2)
      let c = color.oklch(80%, 100%, t*360deg)

      // pt is returned directly by intersection function
      circle(pt, radius: 2pt, fill: c, stroke: none)
      line(pt, ((), 7pt, (rel: x-vel)), stroke: c + 2pt)

      // pt2 is found by sampling the path at the index/t-value returned by the intersection function
      circle(pt2, radius: 4pt, stroke: c)
    }
  })
  

  let o1 = merge-path({
    line((0,0), (3,-1))
    bezier((3,1), (1,1), (1,-1))
  }, stroke: 0.5pt)
  let o2 = circle((2,0), radius: 1)
  show-intersections(o1, o2)
  group(translate(x: 5) + show-intersections(o2, o1))

  translate(y: 3)

  let o1 = bezier-through((0,0), (3,1), (2,0), stroke: 0.5pt)
  let o2 = rect((1.5,-.4), (2.3,1.3))
  show-intersections(o1, o2)
  group(translate(x: 5) + show-intersections(o2, o1))

  translate(y: 3)

  let o1 = bezier((0,0), (3,1), (2,0), stroke: 0.5pt)
  let o2 = rect((1,0), (3,1))
  show-intersections(o1, o2)
  group(translate(x: 5) + show-intersections(o2, o1))

  translate(y: 3)

  let o1 = bezier((2,0), (0,0), (2,2), stroke: 0.5pt)
  let o2 = line((.5, 0.75), (1.3, 0.5))
  show-intersections(o1, o2)
  group(translate(x: 5) + show-intersections(o2, o1))

})