#import "deps.typ": cetz
#import cetz.vector
#import cetz.util: bezier
#import "utils.typ"

#let polar(dist, angle) = (dist*calc.cos(angle), dist*calc.sin(angle), 0.)

/* TERMINOLOGY */
// <path> := (<sub-path>*,)
// <sub-path> := (<origin>, <closed>, (<segment>*,))
// <segment> := ("l" | "c", <vector>*)


/// Simplify a subpath by deleting trivial/zero-length
/// line segments (which end where they begin).
#let simplify-subpath(subpath) = {
  let (start, close, segments) = subpath
  let pt = start
  let i = 0
  while i < segments.len() {
    let (kind, ..pts) = segments.at(i)
    if kind == "l" and pts.first() == pt {
      segments.remove(i)
      continue
    }
    pt = pts.last()
    i += 1
  }
  return (start, close, segments)
}



/// Approximate a circular arc with a cubic Bézier segment.
/// 
/// This similar to `cetz.drawable.arc()` except that it never
/// uses more than one cubic Bézier segment, and it returns just
/// the control and end points `(c1, c2, e)`, not a path.
/// 
/// Single segment approximations are useful because they are more
/// visually robust to nudging endpoints, which is sometimes necessary
/// when creating a rounded corner where two curves meet.
#let cubic-arc(x, y, z, start, stop, rx, ry, fill: none, stroke: none) = {
  let delta = calc.max(-360deg, calc.min(stop - start, 360deg))

  // Move x/y to the center
  x -= rx * calc.cos(start)
  y -= ry * calc.sin(start)

  // Calculation of control points is based on the method described here:
  // https://pomax.github.io/bezierinfo/#circles_cubic
  let segments = ()
  let origin = (x, y, z)

  let k = 4 / 3 * calc.tan(delta / 4)

  let sx = x + rx * calc.cos(start)
  let sy = y + ry * calc.sin(start)
  let ex = x + rx * calc.cos(stop)
  let ey = y + ry * calc.sin(stop)

  let s = (sx, sy, z)
  let c1 = (
    x + rx * (calc.cos(start) - k * calc.sin(start)),
    y + ry * (calc.sin(start) + k * calc.cos(start)),
    z,
  )
  let c2 = (
    x + rx * (calc.cos(stop) + k * calc.sin(stop)),
    y + ry * (calc.sin(stop) - k * calc.cos(stop)),
    z,
  )
  let e = (ex, ey, z)
  return (c1, c2, e)
}



#let modify-single-subpath-element(ctx, element, callback) = {
  assert.eq(element.len(), 1, message: "expected one cetz element")
  let (ctx, drawables) = element.first()(ctx)
  if type(drawables) == dictionary { drawables = (drawables,) }
  assert.eq(drawables.len(), 1, message: "expected one drawable")
  let drawable = drawables.first()
  let path = drawable.segments // these "segments" are actually one *path*
  assert.eq(path.len(), 1, message: "expected one subpath")
  let subpath = path.first()

  let new-subpath = callback(subpath)
  let new-path = (new-subpath,)
  let new-drawable = drawable + (segments: new-path)

  return new-drawable
}

#let draw-only-first-path-segment(element, stroke: auto) = {
  cetz.draw.get-ctx(ctx => {
    let new-drawable = modify-single-subpath-element(ctx, element, subpath => {
      let (origin, closed, segments) = subpath
      return (origin, false, segments.slice(0, 1))
    })
    if stroke != auto { new-drawable.stroke = stroke }
    return (ctx => (
      ctx: ctx,
      drawables: (new-drawable,)
    ),)
  })
}

#let draw-only-last-path-segment(element, stroke: auto) = {
  cetz.draw.get-ctx(ctx => {
    let new-drawable = modify-single-subpath-element(ctx, element, subpath => {
      let (origin, closed, segments) = subpath
      if segments.len() <= 1 {
        return (origin, false, segments.slice(0, 1))
      } else {
        let last = segments.last()
        let second-last = segments.at(-2)
        let (kind, ..coords) = second-last
        return (coords.last(), false, (last,))
      }
    })
    if stroke != auto { new-drawable.stroke = stroke }
    (ctx => (
      ctx: ctx,
      drawables: (new-drawable,)
    ),)
  })
}

#let wrap-angle-180(a) = {
  let t = (a + 180deg)/360deg
  t -= calc.floor(t)
  return t*360deg - 180deg
}

#assert(range(-500, 500).all(a => {
  let b = wrap-angle-180(a*1deg/2)
  -180deg <= b and b < 180deg
}))



/// Offset a vertex to make a miter joint, given the
/// angles of the incoming and outgoing legs.
/// 
/// ```
///      offset vertex ↓
/// ───────────────────* ┐
///      vertex ↓     /  │ offset 
/// ─[i-angle]──@    /   ┘
///            /    /       
///     [o-angle]  /      
///          /    /     
/// ```
#let offset-vertex(
  vertex,
  i-angle,
  o-angle,
  offset,
) = {

  let interior-angle = 180deg + o-angle - i-angle
  let sin = calc.sin(interior-angle/2)

  // give up if corner is too pointy
  if calc.abs(sin) < 0.01 { return vertex }
  
  // distance and angle between vertex and offset vertex
  let hypot = -offset/sin
  let angle = (i-angle + o-angle)/2 + 90deg 

  let offset = (hypot*calc.cos(angle), hypot*calc.sin(angle), 0.0)
  return cetz.vector.add(vertex, offset)
}

  
/// Incoming leg and circular segments of a rounded corner.
/// 
/// Returns the line segment to point `P` and a single cubic
/// Bézier segment to `Q`.
/// 
/// ```
///             ┌─── d ───┐          
/// ************P***──────@-[i-angle]
///        ..   │   **   /           
///       .     r     * /            
///       .     ╵     */             
///       .           Q              
///        ..      ../               
///          ...... /                
///                /                 
///           [o-angle]
/// 
/// @ = vertex
/// * = segments returned by this function
/// ```
#let rounded-vertex(
  vertex,
  i-angle,
  o-angle,
  radius,
) = {
  let interior-angle = i-angle + 180deg - o-angle

  if calc.abs(calc.sin(interior-angle)) < 0.05 {
    return (("l", vertex),)
  }

  let d = radius/calc.tan(interior-angle/2)

  let (start, stop) = (i-angle + 90deg, o-angle + 90deg)
  if stop > start { start += 360deg }
  if start - stop > 180deg {
    d *= -1
    start -= 180deg
    stop += 180deg
  }

  let P = vector.add(vertex, (d*calc.cos(i-angle), d*calc.sin(i-angle)))
  let (c1, c2, Q) = cubic-arc(..P, start, stop, radius, radius)
  return (("l", P), ("c", c1, c2, Q))
}

/// Segments of a miter or bevelled corner.
/// 
/// The bevel is specified by a radius, which defines
/// the circle that is tangent to the bevelled face at
/// the face's midpoint.
/// 
/// Depending on the miter limit, this returns a single segment
/// for a miter join and two line segments for a bevel join,
/// one to point `P` and the other to `Q`.
/// 
/// ```
///                 ┌─ s ─┐
///             ┌ d ┼─────┤          
/// ****************P─────@-[i-angle]
///        ..   │   .**  /           
///       .     r     .*Q            
///       .     ╵     ./             
///       .           /              
///        ..      ../               
///          ...... /                            
///                /                 
///           [o-angle]
/// 
/// @ = vertex
/// * = segments returned by this function
/// ```
#let miter-bevel-vertex(
  vertex,
  i-angle,
  o-angle,
  radius,
  miter-limit: 4.0
) = {
  let interior-angle = wrap-angle-180(i-angle + 180deg - o-angle)

  let inv-miter-ratio = calc.abs(calc.sin(interior-angle/2))
  if inv-miter-ratio > 1/miter-limit or inv-miter-ratio < 1e-5 {
    // not too sharp
    return (("l", vertex),)
  }
  // too sharp; apply bevel

  let beta = 90deg - interior-angle/2

  let is-right-turn = wrap-angle-180(o-angle - i-angle) > 0deg
  let s = if is-right-turn {
    radius*(calc.tan(beta) - calc.tan(beta/2))
  } else {
    radius*(-calc.tan(beta) - 1/calc.tan(beta/2))
  }

  let P = vector.sub(vertex, polar(s, i-angle))
  let Q = vector.add(vertex, polar(s, o-angle))

  return (("l", P), ("l", Q))
}


#let subpath-effect(
  subpath,
  offset: 0,
  min-offset: 0,
  max-offset: 0,
  corner: "miter",
  corner-radius: 0,
  miter-limit: 4.0,
) = {
  let (start, close, segments) = simplify-subpath(subpath)
  let n = segments.len()

  // get the incoming and outgoing angles of each segment
  let io-angles = () // array of (in, out) angle pairs
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
    prev-pt = pts.last()
  }

  let new-segments = ()



  let prev-pt = start
  for i in range(n) {

    //   ┌────────── segment ──────────┐
    // ━━@━[prev-o-angle]━━━━[i-angle]━@━[o-angle]━━━▶︎
    //                                 ^ vertex

    let segment = segments.at(i)
    let vertex = segment.last()

    let (prev-o-angle, i-angle) = io-angles.at(i)
    let o-angle = if i + 1 < n {
      io-angles.at(i + 1).first() 
    } else {
      io-angles.at(i).last()
    }

    let radius = (
      if type(corner-radius) == array { corner-radius.at(i, default: 0) }
      else if type(corner-radius) in (int, float) { corner-radius }
    )


    let corner-type = (
      if type(corner) == array { corner.at(i, default: "miter"); panic() }
      else { corner }
    )

    assert(corner in ("miter", "round"))

    let corner-segments(vertex, ..args) = {
      if corner-type == "miter" { return miter-bevel-vertex(vertex, ..args, miter-limit: miter-limit) }
      if corner-type == "round" { return rounded-vertex(vertex, ..args) }
      panic(corner-type)
    }

    // when a multi-stroke extruded path bends around a corner,
    // we want the innermost path to have the specified radius
    // while outer paths have larger radii such that all paths'
    // centers of curvature are concentric
    let is-right-turn = wrap-angle-180(o-angle - i-angle) > 0deg
    let r = if radius != none {
      if is-right-turn {
        radius - min-offset + offset
      } else {
        radius + max-offset - offset
      }
    }
    r = calc.max(0, r)




    if segment.first() == "l" {

      // apply extrusion effect by offsetting line in normal direction
      if offset != 0 {

        if i == 0 {
          // update start point
          let normal = (offset*calc.sin(i-angle), -offset*calc.cos(i-angle))
          start = vector.add(start, normal)
        }

        vertex = offset-vertex(vertex, i-angle, o-angle, offset)
      }
      
      if radius == none {
        new-segments.push(("l", vertex))
      } else {
        new-segments += corner-segments(vertex, i-angle, o-angle, r)
      }

    } else if segment.first() == "c" {

      let (_, c1, c2, end-pt) = segment
      let s = prev-pt

      assert.eq(end-pt, vertex)

      if new-segments.len() > 0 {
        // shorten curve start curve so it is as near as possible
        // to the previous point, which might have changed from a corner effect
        let new-prev-pt = new-segments.last().last()
        let shift = vector.sub(new-prev-pt, prev-pt)
        let tangent = (calc.cos(prev-o-angle), calc.sin(prev-o-angle), 0)
        let shorten-start = calc.max(0, vector.dot(shift, tangent))
        (s, end-pt, c1, c2) = bezier.cubic-shorten(prev-pt, end-pt, c1, c2, shorten-start)
      }

      if offset != 0 {
        if i == 0 {
          // update start point
          let normal = (offset*calc.sin(prev-o-angle), -offset*calc.cos(prev-o-angle))
          start = vector.add(start, normal)
        }
        
        vertex = offset-vertex(vertex, o-angle, i-angle, offset)
      }

      // shorten curve end to make way for a corner effect
      let new-end-pt = if r != none {
        corner-segments(vertex, i-angle, o-angle, r).first().last()
      } else { vertex }
      let shift = vector.sub(new-end-pt, end-pt)
      let tangent = (calc.cos(i-angle), calc.sin(i-angle), 0)
      let shift-end = vector.dot(shift, tangent) // -ve is shorten, +ve is lengthen
      if shift-end < 0 {
        (s, end-pt, c1, c2) = bezier.cubic-shorten(s, end-pt, c1, c2, shift-end)
      }

      // offset bezier curve by sampling
      let N = 20
      let curve-points = range(N + 1).map(n => {
        let t = n/N
        let pt = bezier.cubic-point(s, end-pt, c1, c2, t)
        let (dx, dy, ..) = bezier.cubic-derivative(s, end-pt, c1, c2, t)
        let unit-normal = vector.norm((dy, -dx))
        vector.add(pt, vector.scale(unit-normal, offset))
      })

      if new-segments.len() > 0 and new-segments.last().first() == "c" {
        // make any previous bezier segment joint continuously to this segment
        new-segments.last().last() = curve-points.first()
      }

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

      // add corner effect at end of bezier segment
      new-segments += corner-segments(vertex, i-angle, o-angle, r).slice(1)
      
      if shift-end > 0 {
        // add overhang line segment if necessary
        new-segments.push(("l", new-end-pt))
      }


    }

    prev-pt = segment.last()
  }

  return (start, close, new-segments)
}


#let path-effect(
  /// -> cetz objects
  path,
  /// -> number | length | array
  shorten-start: 0,
  shorten-end: 0,
  extrude: 0,
  corner: "miter",
  corner-radius: 0,
  stroke: auto,
  miter-limit: 4.0,
) = {
  let extrude = utils.one-or-array(extrude, types: (int, float, length))

  if type(shorten-start) != array {
    shorten-start = (shorten-start,)*extrude.len()
  }
  if type(shorten-end) != array { 
    shorten-end = (shorten-end,)*extrude.len()
  }

  cetz.draw.get-ctx(ctx => {
    let (drawables, bounds, elements) = cetz.process.many(ctx, path)
    // assert.eq(drawables.len(), 1)

    let new-drawables = drawables.map(drawable => {
      assert.eq(drawable.type, "path")

      let stroke = {
        utils.stroke-to-dict(drawable.stroke)
        utils.stroke-to-dict(stroke)
      }
      stroke.miter-limit = miter-limit
      // force round stroke join style for rounded corners
      if corner == "round" { stroke.join = "round" }
      let thickness = utils.get-thickness(stroke).to-absolute()

      let offsets = extrude.map(offset => {
        if type(offset) in (int, float) { offset*thickness/ctx.length }
        else if type(offset) == length { offset/ctx.length }
      })

      for (i, offset) in offsets.enumerate() {
        let new-path = drawable.segments

        // path shortening
        let l = shorten-start.at(i)*thickness/ctx.length
        if l != 0 { 
          new-path = cetz.path-util.shorten-to(new-path, l)
        }
        let l = shorten-end.at(i)*thickness/ctx.length
        if l != 0 { 
          new-path = cetz.path-util.shorten-to(new-path, l, reverse: true)
        }
        
        new-path = new-path.map(subpath => subpath-effect(
          subpath,
          offset: offset,
          min-offset: calc.min(..offsets),
          max-offset: calc.max(..offsets),
          corner: corner,
          corner-radius: corner-radius,
          miter-limit: miter-limit,
        ))

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