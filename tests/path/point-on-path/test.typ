#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: cetz, paths,

#let subpath = ((0,0,0), false, (
  ("l", (10,0,0)),
  ("l", (10,10,0)),
))
#let path = (subpath,)

#let (pos, vel, acc) = paths.point-on-path-by-segment(path, .5)
#assert.eq(pos, (5,0,0))
#assert.eq(vel, (10,0,0))

#let (pos, vel, acc) = paths.point-on-path-by-segment(path, 1)
#assert.eq(pos, (10,0,0))
#assert.eq(vel, (0,10,0))

// at end
#let (pos, vel, acc) = paths.point-on-path-by-segment(path, 2)
#assert.eq(pos, (10,10,0))
#assert.eq(vel, (0,10,0))

// beyond end
#let (pos, vel, acc) = paths.point-on-path-by-segment(path, 3)
#assert.eq(pos, (10,10,0))

#let subpath = ((0,0,0), false, (
  ("c", (1,0,0), (1,1,0), (2,0,0)),
))
#let path = (subpath,)

#let (pos, vel, acc) = paths.point-on-path-by-segment(path, .5)


#page[
#text(green)[Velocity], #text(red)[acceleration]
#cetz.canvas({

  let obj = cetz.draw.merge-path({
    cetz.draw.line((0,0), (1,0), (2,1), (2,0), (3,0))
    cetz.draw.arc-through((3,0), (3.5,0.5), (3,1))
  })
  obj

  cetz.draw.get-ctx(ctx => {
    let drawable = cetz.process.element(ctx, obj.first()).drawables.first()
    let path = drawable.segments
    for it in range(13) {
      it /= 2
      let (pt, vel, accel) = paths.point-on-path-by-segment(path, it)
      cetz.draw.mark(pt, (rel: vel), stroke: 1pt + green, symbol: ">")
      cetz.draw.mark(pt, (rel: accel), stroke: 1pt + red, symbol: ">")
      cetz.draw.circle(pt, radius: 3pt, fill: white, stroke: 0.2pt)
      cetz.draw.content(pt, text(0.3em, raw(repr(it))))
    }

  })
})
]

#page[
Multi-subpath paths
#cetz.canvas({
  cetz.draw.get-ctx(ctx => {
    let path = (
      (
        (0.0, 0.0, 0.0),
        false,
        (
          ("l", (1.0, 0.0, 0.0)),
          ("l", (2.0, 1.0, 0.0)),
          ("l", (2.0, 0.0, 0.0)),
          ("l", (3.0, 0.0, 0.0)),
        ),
      ),
      (
        (0.0, 0.5, 0.0),
        false,
        (
          ("l", (1.0, 1.0, 0.0)),
          ("l", (2.0, 0.5, 0.0)),
          ("l", (3.0, 1.0, 0.0)),
        ),
      ),
    )

    (ctx => (
      ctx: ctx,
      drawables: ((
        type: "path",
        segments: path,
        fill: blue.transparentize(50%),
        stroke: black,
      ),)
    ),)

    for it in range(15).map(x => x/2) {
      let (pt, vel, accel) = paths.point-on-path-by-segment(path, it)
      cetz.draw.circle(pt, radius: 3pt, fill: white, stroke: 0.2pt)
      cetz.draw.content(pt, text(0.3em, raw(repr(it))))
    }
  })
})
]
