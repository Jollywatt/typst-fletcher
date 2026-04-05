#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz, paths

cut path into #text(green)[before] and #text(red)[after]
#cetz.canvas({
  import cetz.draw: *


  let cut-path(obj, cutter) = get-ctx(ctx => {
    let (ctx, drawables, bounds) = cetz.process.many(ctx, obj + cutter)
    let path = drawables.first()
    let cutter = drawables.last()

    let start = paths.intersection.trim-to-intersection(path, cutter, index: 0, from-end: false)
    let end = paths.intersection.trim-to-intersection(path, cutter, index: 0, from-end: true)

    start.stroke = green
    end.stroke = red
    
    group({
      set-transform(none)
      rect(bounds.low, bounds.high, stroke: yellow)
    })
    (ctx => (ctx: ctx, drawables: (path, start, end, cutter)),)
  })

  
  cut-path(merge-path({
    line((0,1), (1,2), (3,1), (1.2,1))
    arc-through((1,1), (2.5,0), (4,1))
  }), line((0,0), (4,2), stroke: blue))

  translate(y: -2.5)

  cut-path(merge-path({
    line((0,1), (1,2), (3,1), (1.2,1))
    arc-through((1,1), (2.5,0), (4,1))
  }), line((0,2), (4,0), stroke: blue))

  translate(y: -2.5)

  cut-path(merge-path({
    line((0,1), (1,2), (3,1), (1.2,1))
    arc-through((1,1), (2.5,0), (4,1))
  }), line((0,.5), (4,.5), stroke: blue))

  translate(y: -2.5)

  cut-path(merge-path({
    line((0,1), (1,2), (3,1), (1.2,1))
    arc-through((1,1), (2.5,0), (4,1))
  }), line((0,1.5), (4,1.5), stroke: blue))
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
    d0 = paths.intersection.trim-to-intersection(d0, d1, from-end: true, index: -1)
    d0 = paths.intersection.trim-to-intersection(d0, d2, index: -1)
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
