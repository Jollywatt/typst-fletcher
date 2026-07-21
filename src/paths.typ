#import "deps.typ": cetz
#import cetz.vector
#import cetz.util: bezier
#import "utils.typ"
#import "intersection.typ"
#import "parsing.typ": is-segment-anchor, interpret-segment-anchor


// TERMINOLOGY
//
// CeTZ paths are arrays of subpaths, which are structures consisting of
// an array of segments.
// 
// <drawable> := (type: "path", segments: <path>, fill: .., stroke: ..)
// <path> := (<sub-path>*,)
// <sub-path> := (<origin>, <closed>, (<segment>*,))
// <segment> := ("l" | "c", <vector>*)
// 
// Warning: CeTZ source code often conflates "subpaths" with "segments".

#let is-segment(it) = type(it) == array and it.len() > 1 and it.first() in "lc"
#let is-subpath(it) = type(it) == array and it.len() == 3 and type(it.at(1)) == bool
#let is-path(it) = type(it) == array and it.all(is-subpath)
#let is-drawable(it) = type(it) == dictionary and it.at("type", default: none) == "path"



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

/// Return the cubic Bézier obtained by clamping the 
/// parameter value $t$ to an interval $[t_0, t_1]$.
#let clamp-cubic-bezier(s, c1, c2, e, t0, t1) = {
  import cetz.vector: lerp
  let cubic(s, c1, c2, e, t1, t2, t3) = lerp(
    lerp(lerp(s, c1, t1), lerp(c1, c2, t1), t2),
    lerp(lerp(c1, c2, t1), lerp(c2, e, t1), t2),
    t3,
  )
  let (s, c1, c2, e) = (
    cubic(s, c1, c2, e, t0, t0, t0),
    cubic(s, c1, c2, e, t1, t0, t0),
    cubic(s, c1, c2, e, t1, t1, t0),
    cubic(s, c1, c2, e, t1, t1, t1),
  )
  return (s, c1, c2, e)
}



/// Return the position, velocity and acceleration vectors of a point
/// at parameter value $t in [0, 1]$ along
/// the $i$th segment of a subpath.
/// -> (array, array, array)
#let point-on-subpath-segment(
  /// A subpath of the form `(start: array, close: bool, segments: array)`.
  /// -> array
  subpath,
  /// The index of the subpath segment.
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

  let (kind, ..pts) = segments.at(segment-index)

  if kind == "l" {
    let x = cetz.vector.lerp(prev-point, pts.last(), segment-t)
    let x-vel = vector.sub(pts.last(), prev-point)
    let x-accel = (0.0, 0.0, 0.0)
    return (x, x-vel, x-accel)
    
  } else if kind == "c" {
    let (c1, c2, end-pt) = pts
    let x = bezier.cubic-point(prev-point, end-pt, c1, c2, segment-t)
    let x-vel = bezier.cubic-derivative(prev-point, end-pt, c1, c2, segment-t)
    let x-accel = cubic-second-derivative(prev-point, end-pt, c1, c2, segment-t)
    return (x, x-vel, x-accel)
  }
}

/// Given a path and an array of stops (segment indices) along the path,
/// return the segment index of a point at a fractional stop.
/// 
/// The path length of stops are linearly interpolated.
#let interp-path-point(path, stops, index) = {
  assert(is-path(path))
  if index >= stops.len() - 1 {
    return stops.last()
  }
  let segment-lengths = cetz.path-util.segment-lengths(path).flatten()
  let cumulative-lengths = (0., ..utils.cumsum(segment-lengths))
  let i-lo = calc.floor(index)
  let i-hi = calc.ceil(index)
  let pathlen-lo = utils.interp(cumulative-lengths, stops.at(i-lo))
  let pathlen-hi = utils.interp(cumulative-lengths, stops.at(i-hi))
  let pathlen-target = utils.lerp(pathlen-lo, pathlen-hi, calc.fract(index))
  let segment-index = utils.interp-inv(cumulative-lengths, pathlen-target)
  return segment-index
}

/// Return the position, velocity and acceleration vectors of a point
/// on a path by its segment index.
/// 
/// The integer part of the segment index refers to which segment the
/// point lies and the fractional part refers to how far along the segment
/// it is (in terms the segment's $t$ parameter, not its path length).
#let point-on-path-by-segment(path, index) = {
  assert(is-path(path))
  if index < 0 {
    let total-segments = path.map(subpath => subpath.last().len()).sum(default: 0)
    index += total-segments
  }
  let subpath-index = 0
  let segment-index = 0
  let i = 0
  while i < calc.floor(index) {
    i += 1
    let subpath-segments = path.at(subpath-index).last()
    if segment-index >= subpath-segments.len() - 1 {
      segment-index = 0
      subpath-index += 1
      if subpath-index >= path.len() {
        // clamp to end
        let last-subpath-segments = path.last().last()
        segment-index = last-subpath-segments.len() - 1
        return point-on-subpath-segment(path.last(), segment-index, 1) 
      }
      continue
    }
    segment-index += 1
  }
  return point-on-subpath-segment(path.at(subpath-index), segment-index, calc.fract(index))
}

#let point-on-path-by-length(ctx, path, l) = {
  assert(is-path(path))
  let lengths = cetz.path-util.segment-lengths(path)
  let total-length = lengths.sum(default: 0).sum(default: 0)

  if total-length == 0 {
    let origin = (0., 0., 0.)
    return (cetz.path-util.first-subpath-start(path), origin, origin)
  }


  let target-length = (
    if type(l) in (int, float) { l }
    else if type(l) == ratio { total-length*float(l) }
    else if type(l) == length { l.to-absolute()/ctx.length }
    else if type(l) == relative {
      total-length*float(l.ratio) + l.length.to-absolute()/ctx.length
    } else { utils.error("invalid path position: #0", l) }
  )
  target-length = calc.clamp(target-length, 0, calc.max(0, total-length - 1e-15))

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




/// Shorten a path from either end by subpath/segment index and $t$-parameter
/// (not by path length, see `cetz.path-util.shorten-to` for that).
#let trim-path(
  /// CeTZ drawable, a dictionary containing key `"segments"`.
  path,
  /// Path index `(subpath-i, segment-i, t)` to start the path from.
  from: none,
  /// Path index `(subpath-i, segment-i, t)` to terminate the path at.
  to: none,
) = {
  assert(is-drawable(path))

  if from != none and to != none {
    (from, to) = (from, to).sorted()
  }

  if to != none {
    let (subpath-i, segment-i, t) = to

    // CETZ NAMING: path.segments are actually subpaths
    let prior-subpaths = path.segments.slice(0, subpath-i)
    let this-subpath = path.segments.at(subpath-i)

    let (start, closed, segments) = this-subpath
    let prior-segments = segments.slice(0, segment-i)
    let this-segment = segments.at(segment-i)

    let prev-pt = {
      if segment-i > 0 { segments.at(segment-i - 1).last() }
      else { start }
    }

    let sliced-segment

    let kind = this-segment.first()
    if kind == "l" {
      let (_, pt) = this-segment
      let new-pt = cetz.vector.lerp(prev-pt, pt, t)
      sliced-segment = ("l", new-pt)

    } else if kind == "c" {
      let s = prev-pt
      let (_, c1, c2, e) = this-segment
      let (lo, hi) = cetz.path-util.bezier.split(s, e, c1, c2, t)
      let (_, e, c1, c2) = lo
      sliced-segment = ("c", c1, c2, e)
    }

    let sliced-subpath = (start, closed, (..prior-segments, sliced-segment))

    // CETZ NAMING: path.segments are actually subpaths
    path.segments = (..prior-subpaths, sliced-subpath)
  }


  if from != none {
    let (subpath-i, segment-i, t) = from

    if to != none and to.slice(0, 2) == (subpath-i, segment-i) {
      // ensure [0, 1] maps onto original segment, even if segment got shortened
      t = t/to.last()
    }

    // CETZ NAMING: path.segments are actually subpaths
    let this-subpath = path.segments.at(subpath-i)
    let post-subpaths = path.segments.slice(subpath-i + 1)

    let (start, closed, segments) = this-subpath
    let this-segment = segments.at(segment-i)
    let post-segments = segments.slice(segment-i + 1)

    let prev-pt = {
      if segment-i > 0 { segments.at(segment-i - 1).last() }
      else { start }
    }

    let sliced-segment

    let kind = this-segment.first()
    if kind == "l" {
      let (_, pt) = this-segment
      let new-pt = cetz.vector.lerp(prev-pt, pt, t)
      sliced-segment = this-segment
      start = new-pt
    } else if kind == "c" {
      let s = prev-pt
      let (_, c1, c2, e) = this-segment
      let (lo, hi) = cetz.path-util.bezier.split(s, e, c1, c2, t)
      let (s, e, c1, c2) = hi
      sliced-segment = ("c", c1, c2, e)
      start = s
    }

    let sliced-subpath = (start, closed, (sliced-segment, ..post-segments))

    // CETZ NAMING: path.segments are actually subpaths
    path.segments = (sliced-subpath, ..post-subpaths)
  }


  path
}


#let intersections(path, targets) = {
  if type(targets) != array { targets = (targets,) }
  (targets.map(target => intersection.path-path(target, path)).join() + ())
    .sorted(key: ((pt, path-index)) => path-index)
}

/// Shorten a path drawable so it starts or ends at an intersection point
/// with another drawable.
/// 
/// If there are multiple intersection points, the path is terminated
/// at the one given by `index`, where intersections are ordered along the
/// path starting from the start or end depending on the trimming mode.
#let trim-to-intersection(
  /// Drawable to truncate, of the form `(type: "path", segments: ..)`.
  /// -> drawable
  path,
  /// Cutting drawables which may intersect the drawable to truncate.
  /// -> array of drawables
  targets,
  /// Whether to trim/shorten the start or end of the path.
  /// -> "start" | "end"
  trim: "start",
  /// Index of the intersection point to use to trim the path.
  /// If trimming from the start, indexing begins at the start of the path;
  /// if trimming from the end, indexing is reversed so it starts at the
  /// intersection closest to the end.
  /// -> int
  index: 0,
) = {

  let pts = intersections(path, targets)
  if pts.len() == 0 { return path }

  if trim == "start" {
    let (pt, path-index) = pts.at(index)
    trim-path(path, from: path-index)
  } else if trim == "end" {
    let (pt, path-index) = pts.rev().at(index)
    trim-path(path, to: path-index)
  }
}


/// Offset a vertex to make a miter joint, given the
/// angles of the incoming and outgoing legs.
/// 
/// ```plain
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
/// ```plain
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
/// ```plain
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
  dynamic-radius: true,
) = {
  
  let (start, close, segments) = simplify-subpath(subpath)

  if close {
    segments.push(segments.first())
  }

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
  let stops = (0,)

  let prev-pt = start
  let first-segment-length = 0
  for i in range(segments.len()) {
    //   ┌────────── segment ──────────┐
    // ━━@━[prev-o-angle]━━━━[i-angle]━@━[o-angle]━━━▶︎
    //                                 ^ vertex

    let segment = segments.at(i)
    let vertex = segment.last()

    let (prev-o-angle, i-angle) = io-angles.at(i)
    let o-angle = if i + 1 < segments.len() {
      io-angles.at(i + 1).first() 
    } else {
      io-angles.at(i).last()
    }

    let radius = (
      if type(corner-radius) == array { corner-radius.at(i, default: 0) }
      else if type(corner-radius) in (int, float) { corner-radius }
    )

    if dynamic-radius {
      // visual adjustment so that tighter bends have smaller radii
      let Δθ = utils.wrap-angle-180(o-angle - i-angle)
      radius *= 1 - (calc.abs(Δθ) - 90deg)/90deg
    }

    let corner-segments(vertex, ..args) = {
      if join == "miter" { 
        miter-bevel-vertex(vertex, ..args, miter-limit: miter-limit) }
      if join == "round" { rounded-vertex(vertex, ..args) }
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
      
      if r == 0 {
        stops.push(new-segments.len() + 1)
        new-segments.push(("l", vertex))
      } else {
        let corner = corner-segments(vertex, i-angle, o-angle, r)
        stops.push(new-segments.len() + (corner.len() + 1)/2)
        new-segments += corner
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
        corner-segments(vertex, i-angle, o-angle, r)
          .first().last()
      } else { vertex }
      let shift = vector.sub(new-end-pt, end-pt)
      let tangent = utils.polar(1, i-angle)
      let shift-end = vector.dot(shift, tangent) // -ve is shorten, +ve is lengthen
      if shift-end < 0 {
        (s, end-pt, c1, c2) = bezier.cubic-shorten(s, end-pt, c1, c2, shift-end)
      }

      // subdivide and offset bezier curve
      let N = 3
      let control-points = range(N).map(n => {
        let (s, c1, c2, e) = clamp-cubic-bezier(s, c1, c2, end-pt, n/N, (n + 1)/N)
        (c1, c2, e)
      }).join()

      let control-segments = control-points.map(pt => ("l", pt))
      let control-subpath = (s, false, control-segments)
      let (offset-subpath, _) = subpath-effect(control-subpath, offset: offset)
      let (new-start, _, new-control-segments) = offset-subpath
      let new-control-points = new-control-segments.map(((_, pt)) => pt)

      if new-segments.len() > 0 and new-segments.last().first() == "c" {
        // make any previous bezier segment joint continuously to this segment
        new-segments.last().last() = new-start
      }

      for (c1, c2, e) in new-control-points.chunks(3) {
        new-segments.push(("c", c1, c2, e))
      }


      if i == 0 { first-segment-length = new-segments.len() }

      // add corner effect at end of bezier segment
      let corner = corner-segments(vertex, i-angle, o-angle, r).slice(1)
      stops.push(new-segments.len() + corner.len()/2)
      new-segments += corner
      
      if shift-end > 0 {
        // add overhang line segment if necessary
        new-segments.push(("l", new-end-pt))
      }

    }

    prev-pt = segment.last()
  }

  if close {
    if new-segments.last().first() == "l" {
      start = new-segments.at(first-segment-length - 1).last()
      new-segments = new-segments.slice(first-segment-length, -1)
      // panic(new-segments.last())
    } else {
      start = new-segments.at(first-segment-length - 1).last()
      new-segments = new-segments.slice(first-segment-length)


    }
    
  }
  return ((start, close, new-segments), stops)
}



// Apply path effects to a CeTZ element.
// 
// A CeTZ element is a dictionary of the form `(name, anchors, drawables)`.
// The `drawables` field is updated with path effects (corner rounding, extrusion,
// shortening) applied and the `anchors` function is updated to accept path segment
// anchors.
#let element-path-effect(
  ctx,
  element,
  stroke: auto,
  fill: auto,
  shorten-start: 0,
  shorten-end: 0,
  extrude: 0,
  join: "miter",
  corner-radius: 0,
  miter-limit: 4.0,
  dynamic-radius: true,
) = {
  if element.drawables.len() != 1 {
    utils.error("path effect requires each element to have one drawable; found #0", element.drawables.len())
  }
  let extrude = utils.one-or-array(extrude, types: (int, float, length))

  if type(shorten-start) != array {
    shorten-start = (shorten-start,)*extrude.len()
  }
  if type(shorten-end) != array { 
    shorten-end = (shorten-end,)*extrude.len()
  }

  // for extruded strokes, `radius: 0` still results in round corners
  // so we let `radius: none` force a non-rounded miter style
  if corner-radius == none {
    corner-radius = 0
    join = "miter"
  }

  let corner-radius = (
    if type(corner-radius) == array {
      corner-radius.map(r => cetz.util.resolve-number(ctx, r))
    } else {
      cetz.util.resolve-number(ctx, corner-radius)
    }
  )


  let anchor-path = none
  let anchor-stops = ()

  let new-drawables = ()
  for drawable in element.drawables {
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
    let offsets = extrude.map(resolve-thickness-multiples).sorted()

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

      let new-stops = ()
      for i in range(new-path.len()) {
        let (subpath, stops) = subpath-effect(
          new-path.at(i),
          offset: offset,
          min-offset: calc.min(..offsets),
          max-offset: calc.max(..offsets),
          join: join,
          corner-radius: corner-radius,
          miter-limit: miter-limit,
          dynamic-radius: dynamic-radius,
        )
        new-path.at(i) = subpath
        new-stops += stops
      }
      anchor-stops = new-stops

      new-drawables.push({
        drawable
        (segments: new-path, stroke: stroke)
        if fill != auto { (fill: fill) }
      })
    }
  }


  let anchors = it => {
    if it == "default" { it = 50% }
    if is-segment-anchor(it) {
      let anchor = interpret-segment-anchor(it)
      let path-anchor(path) = {
        let index = interp-path-point(path, anchor-stops, anchor.segment + anchor.t)
        let (pt, vel, accel) = point-on-path-by-segment(path, index)
        if anchor.at("return-derivatives", default: false) {
          return (pt, vel, accel)
        } else {
          return pt
        }
      }
      if new-drawables.len() == 1 {
        return path-anchor(new-drawables.first().segments)
      } else {
        let a = path-anchor(new-drawables.first().segments)
        let b = path-anchor(new-drawables.last().segments)
        if anchor.at("return-derivatives", default: false) {
          return array.zip(a, b).map(((a, b)) => cetz.vector.lerp(a, b, 0.5))
        } else {
          return cetz.vector.lerp(a, b, 0.5)
        }
      }
    }
    return (element.anchors)(it)
  }

  return (
    ctx: ctx,
    drawables: new-drawables,
    name: element.name,
    anchors: anchors,
  )
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
  /// Fill style for the object, overriding the object's intrinsic
  /// fill style. If `auto`, the fill is unchanged.
  fill: auto,
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
  /// The radius of round or bevelled corners.
  /// 
  /// For round corners, this is the radius of curvature. For bevelled corners, this is the
  /// radius of the tangent circle between the bevel face and the sides of the corner.
  /// 
  /// For extruded paths, the radii at each offset is adjusted so that the circles of curvature
  /// are concentric. At a corner, the inner paths have the specified radius of curvature,
  /// while outer paths have larger radii.
  /// The radius can be negative.
  /// 
  /// The value `none` is short for zero radius with `join: "miter"`.
  /// 
  /// Numbers are interpreted in CeTZ canvas units.
  /// -> number | length | none
  corner-radius: 0,
  /// Miter limit, beyond which miter joints become bevelled.
  /// 
  /// The higher the limit, the pointier corners can be before being bevelled.
  /// -> number
  miter-limit: 4.0,
  /// Whether to dynamically adjust corner radii depending on corner sharpness
  /// for nicer visual results.
  /// When enabled, the corner radius is decreased for bends of less than $90degree$.
  /// 
  /// ```example
  /// #import fletcher.paths: path-effect
  /// #cetz.canvas({
  ///   let obj = cetz.draw.line((0,0), (1,1), (2,0), (2,1), (3,0), (4,0))
  ///   let args = arguments(obj, corner-radius: 5pt, join: "round") 
  ///   path-effect(..args, stroke: green)
  ///   cetz.draw.translate(y: -1)
  ///   path-effect(..args, dynamic-radius: false)
  /// })
  /// ```
  dynamic-radius: true,
) = {
  let extrude = utils.one-or-array(extrude, types: (int, float, length))

  if type(shorten-start) != array {
    shorten-start = (shorten-start,)*extrude.len()
  }
  if type(shorten-end) != array { 
    shorten-end = (shorten-end,)*extrude.len()
  }
  
  if join not in ("miter", "round") {
    utils.error("`join` must be one of #..0; got #1", ("miter", "round"), repr(join))
  }

  cetz.draw.get-ctx(ctx => {
    let corner-radius = (
      if type(corner-radius) == array {
        corner-radius.map(r => cetz.util.resolve-number(ctx, r))
      } else {
        cetz.util.resolve-number(ctx, corner-radius)
      }
    )

    let elements = cetz.process.many(ctx, objs).elements

    for element in elements {
      let new-element = element-path-effect(
        ctx,
        element,
        stroke: stroke,
        fill: fill,
        shorten-start: shorten-start,
        shorten-end: shorten-end,
        extrude: extrude,
        join: join,
        corner-radius: corner-radius,
        miter-limit: miter-limit,
        dynamic-radius: dynamic-radius,
      )
      (ctx => (ctx: ctx, ..new-element),)
    }
  })
}


