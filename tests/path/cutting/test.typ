#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz
#import "/src/intersection.typ": trim-drawable

cut path into #text(green)[before] and #text(red)[after]
#cetz.canvas({
  import cetz.draw: *


  let cut-path(obj, cutter) = get-ctx(ctx => {
    let (ctx, drawables, bounds) = cetz.process.many(ctx, obj + cutter)
    let path = drawables.first()
    let cutter = drawables.last()

    let start = trim-drawable(path, cutter, from-end: false)
    let end = trim-drawable(path, cutter, from-end: true)

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
