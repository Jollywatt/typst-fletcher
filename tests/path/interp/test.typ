#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: cetz, paths

#let tick(pt, vel, i) = {
  cetz.draw.line((rel: ((0,0), 4pt, 90deg, vel), to: pt), (rel: ((0,0), 4pt, -90deg, vel), to: pt), stroke: green)
  cetz.draw.circle(pt, radius: 2pt, fill: green, stroke: none)
  cetz.draw.content(pt, text(white, 5pt, [#i]))
}
#let speck(pt) = cetz.draw.circle(pt, radius: .75pt, stroke: none, fill: white)

#let obj = cetz.draw.merge-path({
  cetz.draw.line((0,0), (0.9,0))
  cetz.draw.arc((0.9,0), start: -90deg, stop: 0deg, radius: 0.1)
  cetz.draw.bezier((1,0.1), (2,0.1), (1,1), (2,1))
  cetz.draw.arc((2,0.1), start: 180deg, stop: 270deg, radius: 0.1)
  cetz.draw.line((3,0), (3.5, 0.5), (3,1))
}, stroke: 2pt)


Points on path by segment index
#cetz.canvas(length: 2cm, {
  obj
  cetz.draw.get-ctx(ctx => {
      let path = cetz.process.element(ctx, obj.first()).drawables.first().segments
      assert(paths.is-path(path))

      let subpath = path.first()
      assert(paths.is-subpath(subpath))

      let n = 8
      for i in range(subpath.last().len()*n + 1) {
        i /= n
        let (pt, vel, accel) = paths.point-on-path-by-segment(path, i)
        speck(pt)
      }

      for i in range(subpath.last().len() + 1) {
        let (pt, vel, accel) = paths.point-on-path-by-segment(path, i)
        tick(pt, vel, i)
      }

  })

})


#pagebreak()

Points on path with manual stops

#let stops = (0, 1.5, 2.5, 3.5, 5, 5.5, 6, 6.5, 7)

#cetz.canvas(length: 2cm, {
  obj

  cetz.draw.get-ctx(ctx => {
    let path = cetz.process.element(ctx, obj.first()).drawables.first().segments
    assert(paths.is-path(path))

    let subpath = path.first()
    assert(paths.is-subpath(subpath))

    let n = 8
    for i in range(stops.len()*n) {
      i /= n
      let z = paths.interp-path-point(path, stops, i)
      let (pt, vel, accel) = paths.point-on-path-by-segment(path, z)
      speck(pt)
    }

    for i in range(stops.len()) {
      // i += .5
      let z = paths.interp-path-point(path, stops, i)
      let (pt, vel, accel) = paths.point-on-path-by-segment(path, z)
      tick(pt, vel, i)
    }


  })
})