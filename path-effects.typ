#import "deps.typ": cetz

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
  
  let n = 20
  let ts = if close { range(n) } else {
    // sample more points near ends of path to improve look of curves
    (0, 0.5,..range(1, n), n - 0.5, n)
  }
  ts.map(t => {
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


    // let vertices = _path-effect(ctx, segments, fn, close: close, style)
    let vertices = path-normals(ctx, segments, sep, close: close)
    let path = cetz.draw.hobby(..vertices, close: close)
    // let path = cetz.draw.catmull(..vertices, close: close)
    // let path = cetz.draw.line(..vertices, close: close)
    return cetz.draw.merge-path(path, close: false, stroke: stroke)
  })
}