#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: cetz, paths

#cetz.canvas({
  import cetz.draw: *

  let show-trimmed(path-fn, stroke: black, ..args) = get-ctx(ctx => {
    let drawable = cetz.process.element(ctx, path-fn.first()).drawables.first()

    let trimmed = paths.trim-path(drawable, ..args)
    trimmed.stroke = stroke

    (ctx => (
      ctx: ctx,
      drawables: (trimmed,)
    ),)
  })

  let gap = 0.05

  let it = line((0,0), (1,1), (1,0), (2,0))
  for segment-i in range(3) {
    it
    show-trimmed(it, stroke: 2pt + green, to: (0, segment-i, 0.5 - gap))
    show-trimmed(it, stroke: 2pt + red, from: (0, segment-i, 0.5 + gap))
    translate(y: -1.5)
  }

  let it = bezier((0,0), (1,1), (1,0), (2,0))
  for t in (0, 0.25, 0.5, 0.75, 1) {
    it
    show-trimmed(it, stroke: 2pt + green, to: (0, 0, t - gap))
    show-trimmed(it, stroke: 2pt + red, from: (0, 0, t + gap))
    translate(y: -1.5)
  }

  let it = merge-path({
    bezier((0,0), (1,1), (1,0), (2,0))
    line((3,0), (3,1))
  })
  for segment-i in range(3) {
    it
    show-trimmed(it, stroke: 2pt + green, to: (0, segment-i, 0.5 - gap))
    show-trimmed(it, stroke: 2pt + red, from: (0, segment-i, 0.5 + gap))
    translate(y: -1.5)
  }

  it
  show-trimmed(it, stroke: 2pt + yellow,
    from: (0, 0, 0.5),
    to: (0, 1, 0.5),
  )
  translate(y: -1.5)
  it
  show-trimmed(it, stroke: 2pt + yellow,
    from: (0, 1, 0.25),
    to: (0, 1, 0.75),
  )
})