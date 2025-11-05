#import "deps.typ": cetz
#import cetz.vector
#import cetz.util: bezier
#import "utils.typ"


// TERMINOLOGY
//
// CeTZ paths are arrays of subpaths, which are structures consisting of
// an array of segments.
// 
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
    if kind == "l" and vector.dist(pts.first(), pt) <= 1e-8 {
      segments.remove(i)
      continue
    }
    pt = pts.last()
    i += 1
  }
  return (start, close, segments)
}




/// Get the second derivative (d²x/dt²) of a cubic bezier at position `t`.
///
/// - a (vector): Start point
/// - b (vector): End point
/// - c1 (vector): Control point 1
/// - c2 (vector): Control point 2
/// - t (float): Position on curve [0, 1]
/// -> vector
#let cubic-second-derivative(a, b, c1, c2, t) = {
  // 6(1-t)(c2 - 2c1 + a) + 6t(b - 2c2 + c1)
  vector.add(
    vector.scale(
      vector.add(c2, vector.add(vector.scale(c1, -2), a)),
      6*(1 - t)
    ),
    vector.scale(
      vector.add(b, vector.add(vector.scale(c2, -2), c1)),
      6 * t
    ),
  )
}


/// Sample a specific segment of a subpath and return the position, velocity,
/// and acceleration vectors.
/// -> (coord, coord, coord)
#let point-on-subpath-segment(
  /// A subpath of the form `(start: coord, close: bool, segments: array)`.
  /// -> array
  subpath,
  /// The index of the subpath's segment.
  /// -> int
  segment-index,
  /// The time parameter of the specified segment, in the interval $[0, 1]$.
  /// -> float
  segment-t,
) = {
  let (start, close, segments) = subpath

  // if beyond end, snap to end
  if segment-index >= segments.len() {
    segment-index = segments.len() - 1
    segment-t = 1
  }

  let prev-point = (
    if segment-index > 0 { segments.at(segment-index - 1).last() }
    else { start }
  )

  let segment = segments.at(segment-index)

  if segment.first() == "l" {
    let x = cetz.vector.lerp(prev-point, segment.last(), segment-t)
    let x-vel = vector.sub(segment.last(), prev-point)
    let x-accel = (0.0, 0.0, 0.0)
    return (x, x-vel, x-accel)
  } else if segment.first() == "c" {
    let (_, c1, c2, end-pt) = segment
    let x = bezier.cubic-point(prev-point, end-pt, c1, c2, segment-t)
    let x-vel = bezier.cubic-derivative(prev-point, end-pt, c1, c2, segment-t)
    let x-accel = cubic-second-derivative(prev-point, end-pt, c1, c2, segment-t)
    return (x, x-vel, x-accel)
  }
}


#let point-on-path-by-segment(path, index) = {
  let index = calc.max(0, index)
  let subpath-index = 0
  let segment-index = 0
  let i = 0
  while i < calc.floor(index) {
    if segment-index > path.at(subpath-index).len() {
      subpath-index += 1
      if subpath-index >= path.len() {
        segment-index = path.last().last().len() - 1
        return point-on-subpath-segment(path.last(), segment-index, 1) 
      }
      segment-index = 0
      continue
    }
    segment-index += 1
    i += 1
  }
  return point-on-subpath-segment(path.at(subpath-index), segment-index, calc.fract(index))
}

#let point-on-path-by-length(ctx, path, l) = {
  let origin = (0., 0., 0.)

  let lengths = cetz.path-util.segment-lengths(path)
  let total-length = lengths.sum().sum()

  let target-length = (
    if type(l) in (int, float) { l }
    else if type(l) == ratio { total-length*float(l) }
    else if type(l) == length { l.to-absolute()/ctx.length }
    else if type(l) == relative {
      total-length*float(l.ratio) + l.length.to-absolute()/ctx.length
    } else { utils.error("invalid path position: #0", l) }
  )
  target-length = calc.clamp(target-length, 0, total-length - 1e-15)

  let acc-length = 0.
  for (subpath-index, subpath) in path.enumerate() {
    for (segment-index, length) in lengths.at(subpath-index).enumerate() {
      if acc-length + length >= target-length {
        let segment-t = (target-length - acc-length)/length
        return point-on-subpath-segment(subpath, segment-index, segment-t)
      }
      acc-length += length
    }
  }

  utils.error("point on path is out of range")
}

/// Get the position, velocity, and acceleration of a point on a path,
/// parametrised either by length or segment number.
#let point-on-path(
  /// Dictionary including the unit length `ctx.length`
  /// for converting lengths into CeTZ units.
  ctx,
  path,
  /// Specify the point by its length along the path (in CeTZ units),
  /// or by its position along the path as a ratio of its total length.
  /// 
  /// For example, `50%` is the midpoint of the path's total length.
  /// 
  /// -> number | ratio
  length: none,
  /// Specify the point by "segment coordinate".
  /// 
  /// The integer part specifies the segment index, and the fractional part
  /// specifies the position along that segment (for Bezier curves, this is the
  /// time parameter, not the arc length).
  /// 
  /// For example, `2.5` is the midpoint of the third segment.
  /// 
  /// -> number
  segment: none,
) = {
  if length != none and segment == none {
    point-on-path-by-length(ctx, path, length)
  } else if length == none and segment != none {
    point-on-path-by-segment(path, segment)
  } else {
    utils.error("only one of `length` or `segment` may be specified")
  }
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


  let offset = utils.polar(hypot, angle)
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

  let P = vector.add(vertex, utils.polar(d, i-angle))
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
  let interior-angle = utils.wrap-angle-180(i-angle + 180deg - o-angle)

  let inv-miter-ratio = calc.abs(calc.sin(interior-angle/2))
  let is-too-sharp = miter-limit == 0 or inv-miter-ratio < 1/miter-limit
  if not is-too-sharp or inv-miter-ratio < 1e-5 {
    // miter joint
    return (("l", vertex),)
  }
  // too sharp; apply bevel

  let beta = 90deg - interior-angle/2

  let is-right-turn = utils.wrap-angle-180(o-angle - i-angle) > 0deg
  let s = if is-right-turn {
    radius*(calc.tan(beta) - calc.tan(beta/2))
  } else {
    radius*(-calc.tan(beta) - 1/calc.tan(beta/2))
  }

  let P = vector.sub(vertex, utils.polar(s, i-angle))
  let Q = vector.add(vertex, utils.polar(s, o-angle))

  return (("l", P), ("l", Q))
}


#let subpath-effect(
  subpath,
  offset: 0,
  min-offset: 0,
  max-offset: 0,
  join: "miter",
  corner-radius: 0,
  miter-limit: 4.0,
) = {
  assert(join in ("miter", "round"))
  
  let (start, close, segments) = simplify-subpath(subpath)

  if close {
    segments.push(segments.first())
  }
  
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
  let first-segment-length = 0
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

    let corner-segments(vertex, ..args) = {
      if join == "miter" { return miter-bevel-vertex(vertex, ..args, miter-limit: miter-limit) }
      if join == "round" { return rounded-vertex(vertex, ..args) }
      panic(join)
    }

    // when a multi-stroke extruded path bends around a corner,
    // we want the innermost path to have the specified radius
    // while outer paths have larger radii such that all paths'
    // centers of curvature are concentric
    let is-right-turn = utils.wrap-angle-180(o-angle - i-angle) > 0deg
    let r = (
      if is-right-turn {
        radius - min-offset + offset
      } else {
        radius + max-offset - offset
      }
    )
    r = calc.max(0, r)




    if segment.first() == "l" {
      if i == 0 { first-segment-length = 1 }

      // apply extrusion effect by offsetting line in normal direction
      if offset != 0 {

        if i == 0 {
          // update start point
          let normal = utils.polar(offset, i-angle - 90deg)
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
        let tangent = utils.polar(1, prev-o-angle)
        let shorten-start = calc.max(0, vector.dot(shift, tangent))
        (s, end-pt, c1, c2) = bezier.cubic-shorten(prev-pt, end-pt, c1, c2, shorten-start)
      }

      if offset != 0 {
        if i == 0 {
          // update start point
          let normal = utils.polar(offset, prev-o-angle - 90deg)
          start = vector.add(start, normal)
        }
        
        vertex = offset-vertex(vertex, o-angle, i-angle, offset)
      }

      // shorten curve end to make way for a corner effect
      let new-end-pt = if r != none {
        corner-segments(vertex, i-angle, o-angle, r).first().last()
      } else { vertex }
      let shift = vector.sub(new-end-pt, end-pt)
      let tangent = utils.polar(1, i-angle)
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

      if i == 0 { first-segment-length = new-segments.len() }

      // add corner effect at end of bezier segment
      new-segments += corner-segments(vertex, i-angle, o-angle, r).slice(1)
      
      if shift-end > 0 {
        // add overhang line segment if necessary
        new-segments.push(("l", new-end-pt))
      }


    }

    prev-pt = segment.last()
  }

  if close {
    start = new-segments.at(first-segment-length - 1).last()
    new-segments = new-segments.slice(first-segment-length, -1)
  }

  return (start, close, new-segments)
}

/// Apply path effects (extrusion and shortening) to a CeTZ object, returning
/// a CeTZ object.
#let path-effect(
  /// CeTZ objects to apply the path effect to.
  /// 
  /// A CeTZ object is an array of functions; the result of `cetz.draw.line(..)`
  /// or `cetz.draw.merge-path(..)`, for example.
  /// -> cetz objects
  objs,
  /// Stroke style for the object, overriding the object's intrinsic stroke style.
  stroke: auto,
  /// Trim the beginning of the path by a given length.
  /// 
  /// For multi-stroke effect when @path-effect.extrude is an array,
  /// this may also be an array of the same length, specifying the length
  /// to shorten each offset path individually.
  /// This is useful for placing marks on multi-stroke lines correctly.
  /// 
  /// Numbers are interpreted as multiples of the stroke's thickness.
  /// -> number | length | array
  shorten-start: 0,
  /// Trim the end of the path by a specific length.
  /// 
  /// Works just like @path-effect.shorten-start.
  /// -> number | length | array
  shorten-end: 0,
  /// Lengths to offset path by. An array of different offsets results in
  /// multiple parallel strokes.
  /// 
  /// Numbers are interpreted as multiples of the stroke's thickness.
  /// 
  /// ```example
  /// #import fletcher.paths: path-effect
  /// #cetz.canvas({
  ///   import cetz.draw: *
  ///   set-style(stroke: 5pt)
  ///   let obj = line((0,0), (1,1), (2,0))
  ///   obj
  ///   path-effect(obj, extrude: (+2, -2),
  ///                    stroke: blue)
  /// })
  /// ```
  /// 
  /// -> number | length | array
  extrude: 0,
  /// How to form corners of an offset path.
  /// 
  /// If `"round"`, corners become rounded joints with a (minimum) corner radius
  /// specified by @path-effect.corner-radius.
  /// If `"miter"`, corners become miter joints or, if they are sharp enough, bevelled
  /// joints, as controlled by @path-effect.miter-limit.
  /// 
  /// ```example
  /// #import fletcher.paths: path-effect
  /// #cetz.canvas({
  ///   import cetz.draw: *
  ///   set-style(stroke: 2pt)
  ///   let obj = line((0,0), (1,1),
  ///                  (1,0), (2,0))
  ///   path-effect(obj, extrude: (-1, +1),
  ///     join: "round", corner-radius: .2)
  ///   translate(y: -1.5)
  ///   path-effect(obj, extrude: (-1, +1))
  ///   translate(y: -1.5)
  ///   path-effect(obj, extrude: (-1, +1),
  ///     miter-limit: 2)
  /// })
  /// ```
  /// 
  /// -> "miter" | "round"
  join: "miter",
  /// The radius of round of bevelled corners.
  /// 
  /// For round corners, this is the radius of curvature. For bevelled corners, this is the
  /// radius of the tangent circle between the bevel face and the sides of the corner.
  /// 
  /// For extruded paths, the radii at each offset is adjusted so that the circles of curvature
  /// are concentric. At a corner, the inner paths have the specified radius of curvature,
  /// while outer paths have larger radii.
  /// The radius can be negative.
  /// 
  /// Numbers are interpreted in CeTZ canvas units.
  /// -> number | length
  corner-radius: 0,
  /// Miter limit, beyond which miter joints become bevelled.
  /// 
  /// The higher the limit, the pointier corners can be before being bevelled.
  /// -> number
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
    let corner-radius = (
      if type(corner-radius) == array {
        corner-radius.map(r => cetz.util.resolve-number(ctx, r))
      } else {
        cetz.util.resolve-number(ctx, corner-radius)
      }
    )

    let (drawables, bounds, elements) = cetz.process.many(ctx, objs)
    let new-drawables = drawables.map(drawable => {
      assert.eq(drawable.type, "path")

      let stroke = {
        utils.stroke-to-dict(drawable.stroke)
        utils.stroke-to-dict(stroke)
      }
      stroke.miter-limit = miter-limit
      // force round stroke join style for rounded corners
      if join == "round" { stroke.join = "round" }
      let thickness = utils.get-thickness(stroke).to-absolute()

      let resolve-thickness-multiples(x) = {
        if type(x) in (int, float) { x*thickness/ctx.length }
        else if type(x) == length { x.to-absolute()/ctx.length }
      }

      let offsets = extrude.map(resolve-thickness-multiples)

      for (i, offset) in offsets.enumerate() {
        let new-path = drawable.segments

        // path shortening
        let l = resolve-thickness-multiples(shorten-start.at(i))
        if l != 0 { 
          new-path = cetz.path-util.shorten-to(new-path, l)
        }
        let l = resolve-thickness-multiples(shorten-end.at(i))
        if l != 0 { 
          new-path = cetz.path-util.shorten-to(new-path, l, reverse: true)
        }
        
        new-path = new-path.map(subpath => subpath-effect(
          subpath,
          offset: offset,
          min-offset: calc.min(..offsets),
          max-offset: calc.max(..offsets),
          join: join,
          corner-radius: corner-radius,
          miter-limit: miter-limit,
        ))

        (drawable + (segments: new-path, stroke: stroke),)
      }
    }).join() + () // coerce none to array

  
    (ctx => {
      return (
        ctx: ctx,
        drawables: new-drawables,
      )
    },)
  })
}

