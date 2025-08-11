#import "deps.typ": cetz
#import cetz.vector

#let get-segments(ctx, target) = {
  if type(target) == array {
    assert.eq(target.len(), 1,
      message: "Expected a single element, got " + str(target.len()))
    target = target.first()
  }

  let (ctx, drawables, ..) = cetz.process.element(ctx, target)
  if drawables == none or drawables == () {
    return ()
  }

  let first = drawables.first()
  let closed = cetz.path-util.first-subpath-closed(first.segments)
  return (segments: first.segments, close: closed)
}


#let path-normals(ctx, segments, sep, close: false) = {
  let len = cetz.path-util.length(segments)
  
  let n = 24
  range(n + 1).map(t => {
    let (point, direction) = cetz.path-util.point-at(segments, t/n*len)
    let (x, y, ..) = cetz.vector.norm(direction)
    point = cetz.vector.add(point, (-y*sep, x*sep))
    cetz.util.revert-transform(ctx.transform, point)
  })
}


#let extrude(target, sep, stroke: auto) = {
  cetz.draw.get-ctx(ctx => {
    let (segments, close) = get-segments(ctx, target)

    let sep = cetz.util.resolve-number(ctx, sep)
    let vertices = path-normals(ctx, segments, sep, close: close)
    let path = cetz.draw.hobby(..vertices, close: close, omega: (1,1))
    // let path = cetz.draw.line(..vertices, close: close, omega: (1,1))
    return cetz.draw.merge-path(path, close: false, stroke: stroke)
  })
}

#let extrude-vertices(vertices, sep, close: false) = {
  let angles = ()
  for i in range(vertices.len() - 1) {
    let (this, next) = (vertices.at(i), vertices.at(i + 1))
    angles.push(cetz.vector.angle2(this, next))
  }

  let new-vertices = ()
  for i in range(vertices.len()) {

    let angle-this = angles.at(calc.clamp(i, 0, angles.len() - 1))
    let angle-prev = angles.at(calc.clamp(i - 1, 0, angles.len() - 1))

    if close {
      if i == 0 { angle-prev = angles.last() }
      if i == angles.len() { angle-prev = angles.first() }
    }

    let half-knee-angle = (180deg + angle-this - angle-prev)/2
    let hypot = sep/calc.sin(half-knee-angle)
    let angle = angle-prev + half-knee-angle
    let normal = (hypot*calc.cos(angle), hypot*calc.sin(angle))
    new-vertices.push(vector.add(vertices.at(i), normal))
  }
  
  return new-vertices
}

#let extrude-line(target, sep, stroke: auto) = {
  cetz.draw.get-ctx(ctx => {
    let sep = cetz.util.resolve-number(ctx, sep)
    let (drawables, bounds) = cetz.process.many(ctx, target)

    let new-drawables = drawables.map(drawable => {
      assert.eq(drawable.type, "path")

      let new-segments = drawable.segments.map(segment => {
        let (start, close, path) = segment

        let vertices = (start,) + path.map(((kind, coord, ..)) => {
          assert.eq(kind, "l")
          return coord
        })

        let new-vertices = extrude-vertices(vertices, sep, close: close)
        let (start, ..vertices) = new-vertices

        (start, close, vertices.map(v => ("l", v)))
      })

      return drawable + (segments: new-segments, stroke: stroke)
    })

  
    (ctx => {
      return (
        ctx: ctx,
        drawables: new-drawables,
      )
    },)

  })
}