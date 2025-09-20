#import "deps.typ": cetz
#import cetz.vector
#import cetz.util: bezier
#import "utils.typ"

/* TERMINOLOGY */
// segment := ("l" | "c", vector*)
// sub-path := (<origin>, <closed?>, (segment*,))
// path := (sub-path*,)

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
  return cetz.draw.get-ctx(ctx => {
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

#let extrude-subpath(subpath, sep, corner-radius) = {
  let (start, close, segments) = subpath
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
    let segment-kind = segment.first()

    // get incoming and outgoing angles of the current and adjacent segments
    // >---[o-angle-prev]-*-[i-angle]-----[o-angle]-*-[i-angle-next]--->
    //                    ^ i-vertex                ^ o-vertex

    let (i-vertex, o-vertex) = (vertices.at(i), vertices.at(i + 1))
    let (i-angle, o-angle) = io-angles.at(i)

    let o-angle-prev = {
      if i == 0 {
        if close { io-angles.last().last() }
        else { io-angles.first().first() }
      } else { io-angles.at(i - 1).last() }
    }

    let i-angle-next = {
      if i == n - 1 {
        if close { io-angles.first().first() }
        else { io-angles.last().last() }
      } else { io-angles.at(i + 1).first() }
    }
    

    // add points to form a bevel joint
    // each bevel joint has two vertices, while elbows have one

    let should-make-bevel(o-angle, i-angle) = {
      // true if extrusion is toward the outside of a sharp bend
      let is-sharp = calc.abs(o-angle - i-angle) > 120deg
      if o-angle < i-angle { o-angle += 360deg }
      let is-outer-corner = (o-angle - i-angle < 180deg) == (sep > 0)
      return is-sharp and is-outer-corner
    }

    let i-is-bevel = should-make-bevel(o-angle-prev, i-angle) and (close or i > 0) 
    let o-is-bevel = should-make-bevel(o-angle, i-angle-next) and (close or i < n - 1)


    // bevel vertex at start of segment
    if i-is-bevel {
      let outward-mid-angle = wrap-angle-180(i-angle + 180deg - o-angle-prev)/2 + o-angle-prev
      let normal = i-angle + sep.signum()*90deg

      let h = wrap-angle-180(outward-mid-angle - normal)/2
      let a = normal + h

      if calc.abs(h) == 90deg {
        // edge case that I don't understand
      } else {
        let bevel = calc.abs(sep/calc.cos(h))
        bevel = calc.min(bevel, 5)
        let delta = (bevel*calc.cos(a), bevel*calc.sin(a), 0.0)
        new-segments.push(("l", vector.add(i-vertex, delta)))

        if i == 0 { start = vector.add(i-vertex, delta) }
      }
    }




    // add elbow point at end of segment

    let i-mid = (o-angle-prev + i-angle)/2 + 90deg
    let o-mid = (o-angle + i-angle-next)/2 + 90deg

    let i-half-knee-angle = (180deg + i-angle - o-angle-prev)/2
    let i-hypot = sep/calc.sin(i-half-knee-angle)
    let i-pt = (i-hypot*calc.cos(i-mid), i-hypot*calc.sin(i-mid), 0.0)

    let o-half-knee-angle = (180deg + i-angle-next - o-angle)/2
    let o-hypot = sep/calc.sin(o-half-knee-angle)
    let o-pt = (o-hypot*calc.cos(o-mid), o-hypot*calc.sin(o-mid), 0.0)

    if i == 0 and not i-is-bevel { start = vector.add(i-vertex, i-pt) }

    let (kind, ..pts) = segment
    if kind == "l" {
      if not last-segment-was-line and i > 0 and not i-is-bevel {
        new-segments.push(("l", vector.add(i-vertex, i-pt)))
        // new-segments.push(("l", i-vertex))
      }
      if not o-is-bevel {
        new-segments.push(("l", vector.add(o-vertex, o-pt)))
        // new-segments.push(("l", o-vertex))
      }
      last-segment-was-line = true

    } else if kind == "c" {
      // extrude a cubic bezier segment >.<

      let s = i-vertex
      let (c1, c2, e) = pts
      assert.eq(e, o-vertex)
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

    // bevel vertex at end of segment
    if o-is-bevel and segment-kind == "l" {
      let outward-mid-angle = wrap-angle-180(i-angle-next + 180deg - o-angle)/2 + o-angle
      let normal = o-angle + sep.signum()*90deg
      let h = wrap-angle-180(outward-mid-angle - normal)/2
      let a = normal + h

      let bevel = calc.abs(sep/calc.cos(h))
      bevel = calc.min(bevel, 5)
      let delta = (bevel*calc.cos(a), bevel*calc.sin(a), 0.0)
      new-segments.push(("l", vector.add(o-vertex, delta)))
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
  corner-radius: 0,
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

    let (drawables, bounds, elements) = cetz.process.many(ctx, target)

    assert.eq(drawables.len(), 1)

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
            extrude-subpath(subpath, offset, corner-radius)
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


/// Given the coordinate of a vertex and the angles of its
/// incoming and outgoing legs (`i-angle` and `o-angle`),
/// return the incoming leg extruded by an offset.
/// 
/// ```
///       ┌ █████████████ 
/// offset│            /   
///       └ ────-@ - -/---[i-angle]
///             /    /       
///            /    /      
///           /         
///      [o-angle]
/// 
/// @ = vertex
/// █ = segments returned by this function
/// ```
#let offset-vertex(
  vertex,
  i-angle,
  o-angle,
  offset,
) = {

  let mid = (i-angle + o-angle)/2 + 90deg
  let interior-angle = 180deg + o-angle - i-angle
  let sin = calc.sin(interior-angle/2)
  let hypot = (
    if calc.abs(sin) < 0.01 { 0 }
    else { -offset/sin }
  )
  let knee-offset = (hypot*calc.cos(mid), hypot*calc.sin(mid), 0.0)

  vertex = cetz.vector.add(vertex, knee-offset)
}

/// Given the coordinate of a vertex and the angles of its
/// incoming and outgoing legs (`i-angle` and `o-angle`),
/// return the incoming leg and arc of a rounded vertex.
/// 
/// ```
///             ┌─── d ───┐          
/// ████████████████──────@--[i-angle]
///        ..   │   ██   /           
///       .     r     █ /            
///       .     |     █/             
///       .           █              
///        ..      ../               
///          ...... /                
///                /                 
///           [o-angle]
/// 
/// @ = vertex
/// █ = segments returned by this function
/// ```
#let rounded-vertex(
  vertex,
  i-angle,
  o-angle,
  radius,
) = {
      

  let new-segments = ()

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

  let arc-start-pt = cetz.vector.add(vertex, (d*calc.cos(i-angle), d*calc.sin(i-angle)))
  let arc = cetz.drawable.arc(..arc-start-pt, start, stop, radius, radius)
  let (arc-start, _, arc-segments) = arc.segments.first()

  new-segments.push(("l", arc-start))
  new-segments += arc-segments
  new-segments.push((
    "l",
    cetz.vector.sub(vertex, (d*calc.cos(o-angle), d*calc.sin(o-angle)))
  ))

  return new-segments
}

#let subpath-effect(
  subpath,
  offset: 0,
  min-offset: 0,
  max-offset: 0,
  corner-radius: none,
) = {
  let (start, close, segments) = subpath
  let n = segments.len()

  // first, get the incoming and outgoing angles of each segment piece
  let io-angles = () // array of (in, out) angle pairs, one of each segment
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

  let prev-pt = start
  for i in range(n) {

    let this-segment = segments.at(i)
    let i-angle = io-angles.at(i).last() // end angle of this segment
    if i == n - 1 {
      // last segment
      // new-segments.push(this-segment)
      let vertex = this-segment.last()
      let this-normal = (offset*calc.sin(i-angle), -offset*calc.cos(i-angle))

      vertex = cetz.vector.add(vertex, this-normal)
      new-segments.push(("l", vertex))

      continue
    }

    let next-segment = segments.at(i + 1)
    let o-angle = io-angles.at(i + 1).first() // start angle of next segment

    // this segment and the next are straight lines
    // here we can apply vertex rounding
    if this-segment.first() == "l" and next-segment.first() == "l" {
      let vertex = this-segment.last()

      if offset != 0 {
        let this-normal = (offset*calc.sin(i-angle), -offset*calc.cos(i-angle))

        if i == 0 {
          // update start
          start = cetz.vector.add(start, this-normal)
        }

        let mid = (i-angle + o-angle)/2 + 90deg
        let half-knee-angle = (180deg + o-angle - i-angle)/2
        let sin = calc.sin(half-knee-angle)
        let hypot = (
          if calc.abs(sin) < 0.01 { 0 }
          else { -offset/sin }
        )
        let knee-offset = (hypot*calc.cos(mid), hypot*calc.sin(mid), 0.0)

        vertex = cetz.vector.add(vertex, knee-offset)

      }

      let radius = (
        if type(corner-radius) == array { corner-radius.at(i, default: 0) }
        else if type(corner-radius) in (int, float) { corner-radius }
      )

      if radius == none {
        new-segments.push(("l", vertex))
      } else {

        let is-right-turn = wrap-angle-180(o-angle - i-angle) > 0deg

        let r = if is-right-turn {
          radius - min-offset + offset
        } else {
          // offset - radius
          radius + max-offset -  offset
        }

        new-segments += rounded-vertex(vertex, i-angle, o-angle, r)
      }

    } else {
      new-segments.push(this-segment)
    }

    prev-pt = this-segment.last()
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
  corner-radius: none,
  stroke: auto,
) = {
  let extrude = utils.one-or-array(extrude, types: (int, float, length))

  if type(shorten-start) != array {
    shorten-start = (shorten-start,)*extrude.len()
  }
  if type(shorten-end) != array { 
    shorten-end = (shorten-end,)*extrude.len()
  }

  cetz.draw.get-ctx(ctx => {


    let style = cetz.styles.resolve(ctx, base: (stroke: stroke), root: "line")

    let (drawables, bounds, elements) = cetz.process.many(ctx, path)

    assert.eq(drawables.len(), 1)

    let new-drawables = drawables.map(drawable => {
      assert.eq(drawable.type, "path")

      let stroke = {
        utils.stroke-to-dict(drawable.stroke)
        utils.stroke-to-dict(stroke)
      }
      let thickness = utils.get-thickness(stroke).to-absolute()

      let offsets = extrude.map(offset => {
        if type(offset) in (int, float) { offset*thickness/ctx.length }
        else if type(offset) == length { offset/ctx.length }
        else {panic()}
      })

      for (i, offset) in offsets.enumerate() {

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
        
        new-path = new-path.map(subpath => subpath-effect(
          subpath,
          offset: offset,
          min-offset: calc.min(..offsets),
          max-offset: calc.max(..offsets),
          corner-radius: corner-radius,
        ))

        if corner-radius != none { stroke.join = "round" }

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