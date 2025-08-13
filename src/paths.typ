#import "deps.typ": cetz
#import cetz.vector
#import cetz.util: bezier
#import "utils.typ"

#let extrude-segment(segment, sep) = {
  let (start, close, pieces) = segment
  pieces = pieces.dedup()
  let n = pieces.len()

  // first, get the incoming and outgoing angles of each segment piece
  let io-angles = ()
  let vertices = ()
  let prev-pt = start
  for piece in pieces {
    let (kind, ..pts) = piece
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

  let new-pieces = ()
  let last-piece-was-line = false

  for (i, piece) in pieces.enumerate() {

    // ----[o-angle-prev]->@-[i-angle]----[o-angle]->@-[i-angle-next]---->
    //                     ^ vertices.at(i)          ^ vertices.at(i + 1)

    let (i-angle, o-angle) = io-angles.at(i)
    let o-angle-prev = io-angles.at(calc.clamp(i - 1, 0, n - 1)).last()
    let i-angle-next = io-angles.at(calc.clamp(i + 1, 0, n - 1)).first()
    if close {
      if i == 0 { o-angle-prev = io-angles.last().last() }
      if i == n - 1 { i-angle-next = io-angles.first().first() }
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

    let (kind, ..pts) = piece
    if kind == "l" {
      if not last-piece-was-line {
        new-pieces.push(("l", vector.add(vertices.at(i), i-pt)))
      }
      new-pieces.push(("l", vector.add(vertices.at(i + 1), o-pt)))
      last-piece-was-line = true

    } else if kind == "c" {

      let s = vertices.at(i)
      let (c1, c2, e) = pts
      let ctrls = (s, e, c1, c2)
      let lead = sep/calc.tan(i-half-knee-angle)
      let lag = sep/calc.tan(o-half-knee-angle)

      let t0 = -lead.signum()*bezier.cubic-t-for-distance(..ctrls, calc.abs(lead))
      let t1 = 1 + lag.signum()*(1 - bezier.cubic-t-for-distance(..ctrls, -calc.abs(lag)))

      let N = 20
      let start = if i == 0 { 0 } else { int(last-piece-was-line) }
      let stop = if i == n - 1 { N + 1 } else { N }

      let curve-points = range(start, stop).map(n => {
        let t = utils.lerp(t0, t1, n/N)
        let pt = bezier.cubic-point(..ctrls, t)
        
        let (dx, dy, ..) = bezier.cubic-derivative(..ctrls, t)
        let unit-normal = vector.norm((-dy, dx))
        vector.add(pt, vector.scale(unit-normal, sep))
      })

      if true {
        // approximate curves with a Catmull-Rom curve through samples points
        let bezier = bezier.catmull-to-cubic(curve-points, .5)
        for (s, e, c1, c2) in bezier {
          new-pieces.push(("c", c1, c2, e))
        }
      } else {
        // approximate curves with line segments
        for pt in curve-points {
          new-pieces.push(("l", pt))
        }
      }

      last-piece-was-line = false
    }
  }

  return (start, close, new-pieces)
}



#let extrude(target, sep, stroke: auto) = {
  let sep = utils.one-or-array(sep, types: (int, float, length))

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

      for s in sep {
        if type(s) in (int, float) { s *= thickness/ctx.length }
        else if type(s) == length { s /= ctx.length }

        if s == 0 {
          (drawable + (stroke: stroke),)
          continue
        }
        
        let new-segments = drawable.segments.map(segment => {
          extrude-segment(segment, s)
        })

        (drawable + (segments: new-segments, stroke: stroke),)

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