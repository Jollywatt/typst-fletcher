#import "deps.typ": cetz
#import cetz.vector
#import cetz.util: bezier
#import "utils.typ"

/* TERMINOLOGY */
// segment := ("l" | "c", vector*)
// sub-path := (<origin>, <closed?>, (segment*,))
// path := (sub-path*,)


#let extrude-subpath(subpath, sep) = {
  let (start, close, segments) = subpath
  segments = segments.dedup()
  let n = segments.len()

  // first, get the incoming and outgoing angles of each segment piece
  let io-angles = ()
  let vertices = ()
  let prev-pt = start
  for segment in segments {
    let (kind, ..pts) = segment
    if kind == "l" {
      let angle = vector.angle2(prev-pt, pts.first())
      io-angles.push((angle, angle))
    } else if kind == "c" {
      let (a, b, c) = pts
      io-angles.push((
        vector.angle2(prev-pt, a),
        vector.angle2(b, c),
      ))
    }
    vertices.push(prev-pt)
    prev-pt = pts.last()
  }
  vertices.push(prev-pt)

  let new-segments = ()
  let last-segment-was-line = false

  for (i, segment) in segments.enumerate() {

    // ----[o-angle-prev]->@-[i-angle]----[o-angle]->@-[i-angle-next]---->
    //                     ^ vertices.at(i)          ^ vertices.at(i + 1)

    let (i-angle, o-angle) = io-angles.at(i)

    let o-angle-prev = {
      if i == 0 {
        if close { io-angles.last().last() }
        else { io-angles.first().first() }
      }
      else { io-angles.at(i - 1).last() }
    }

    let i-angle-next = {
      if i == n - 1 {
        if close { io-angles.first().first() }
        else { io-angles.last().last() }
      } else { io-angles.at(i + 1).first() }
    }
    

    let i-mid = (o-angle-prev + i-angle)/2 + 90deg
    let o-mid = (o-angle + i-angle-next)/2 + 90deg

    let i-half-knee-angle = (180deg + i-angle - o-angle-prev)/2
    let i-hypot = sep/calc.sin(i-half-knee-angle)
    let i-pt = (i-hypot*calc.cos(i-mid), i-hypot*calc.sin(i-mid), 0.0)

    let o-half-knee-angle = (180deg + i-angle-next - o-angle)/2
    let o-hypot = sep/calc.sin(o-half-knee-angle)
    let o-pt = (o-hypot*calc.cos(o-mid), o-hypot*calc.sin(o-mid), 0.0)

    if i == 0 {
      start = vector.add(start, i-pt)
    }

    let (kind, ..pts) = segment
    if kind == "l" {
      if not last-segment-was-line and i > 0 {
        new-segments.push(("l", vector.add(vertices.at(i), i-pt)))
      }
      new-segments.push(("l", vector.add(vertices.at(i + 1), o-pt)))
      last-segment-was-line = true

    } else if kind == "c" {

      let s = vertices.at(i)
      let (c1, c2, e) = pts
      let ctrls = (s, e, c1, c2)
      let lead = sep/calc.tan(i-half-knee-angle)
      let lag = sep/calc.tan(o-half-knee-angle)

      let t0 = -lead.signum()*bezier.cubic-t-for-distance(..ctrls, calc.abs(lead))
      let t1 = 1 + lag.signum()*(1 - bezier.cubic-t-for-distance(..ctrls, -calc.abs(lag)))
      let N = 20
      let lo = if i == 0 { 0 } else { int(last-segment-was-line) }
      let hi = if i == n - 1 { N + 1 } else { N }

      let curve-points = range(lo, hi).map(n => {
        let t = utils.lerp(t0, t1, n/N)
        let pt = bezier.cubic-point(..ctrls, t)
        
        let (dx, dy, ..) = bezier.cubic-derivative(..ctrls, t)
        let unit-normal = vector.norm((-dy, dx))
        vector.add(pt, vector.scale(unit-normal, sep))
      })

      if true {
        // approximate curves with a Catmull-Rom curve through samples points
        for (s, e, c1, c2) in bezier.catmull-to-cubic(curve-points, .5) {
          new-segments.push(("c", c1, c2, e))
        }
      } else {
        // approximate curves with line segments
        for pt in curve-points {
          new-segments.push(("l", pt))
        }
      }

      last-segment-was-line = false
    }
  }

  return (start, close, new-segments)
}

/// Apply extrusions to a path and truncate the extrusions from the start and/or end.
/// 
/// ```example
/// #cetz.canvas({
///   import cetz.draw: *
///   let obj = line(stroke: 3pt,
///     (0,0), (1,1), (2,0), (4,0))
///   obj
///   fletcher.paths.extrude-and-shorten(
///     obj,
///     extrude: (-4, -2, 2, 4),
///     shorten-start: (0, 0, 2, 4),
///     shorten-end: (4, 4, 0, 0),
///     stroke: red,
///   )
/// })
/// ```
#let extrude-and-shorten(
  /// -> cetz objects
  target,
  /// -> number | length | array
  extrude: 0,
  shorten-start: 0,
  shorten-end: 0,
  stroke: auto,
) = {
  let offsets = utils.one-or-array(extrude, types: (int, float, length))

  if type(shorten-start) != array {
    shorten-start = (shorten-start,)*offsets.len()
  }
  if type(shorten-end) != array { 
    shorten-end = (shorten-end,)*offsets.len()
  }


  cetz.draw.get-ctx(ctx => {
    let style = cetz.styles.resolve(ctx, base: (stroke: stroke), root: "line")

    let (drawables, bounds) = cetz.process.many(ctx, target)

    let new-drawables = drawables.map(drawable => {
      assert.eq(drawable.type, "path")

      let stroke = {
        utils.stroke-to-dict(drawable.stroke)
        utils.stroke-to-dict(stroke)
      }
      let thickness = utils.get-thickness(stroke).to-absolute()

      for (i, offset) in offsets.enumerate() {
        if type(offset) in (int, float) { offset *= thickness/ctx.length }
        else if type(offset) == length { offset /= ctx.length }

        let start = shorten-start.at(i)*thickness/ctx.length
        let end = shorten-end.at(i)*thickness/ctx.length

        let new-path = drawable.segments

        // path shortening
        if start != 0 { 
          new-path = cetz.path-util.shorten-to(new-path, start)
        }
        if end != 0 { 
          new-path = cetz.path-util.shorten-to(new-path, end, reverse: true)
        }
        
        // path extrusion
        if offset != 0 {
          new-path = new-path.map(subpath => {
            extrude-subpath(subpath, offset)
          })
        }


        (drawable + (segments: new-path, stroke: stroke),)
      }
    }).join()

  
    (ctx => {
      return (
        ctx: ctx,
        drawables: new-drawables,
      )
    },)
  })
}