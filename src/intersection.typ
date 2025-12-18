#import "deps.typ": cetz
#import cetz.util
#import cetz.util.bezier: _cubic-roots, cubic-point
#import "utils.typ": is-drawable

// much of this code is copied from cetz's path-util and bezier source files
// intersection functions by the same name are augmented here
// to return the location of the intersection points along with
// their corresponding path t parameters 


/// Identical to `cetz.intersection.line-line` but returns
/// a pair `(pt, t)` of the point and its t parameter along
/// the a-b line segment (or `none`).
#let line-line(a, b, c, d, ray: false) = {
  let lli8(x1, y1, x2, y2, x3, y3, x4, y4) = {
    let nx = (x1*y2 - y1*x2)*(x3 - x4)-(x1 - x2)*(x3*y4 - y3*x4)
    let ny = (x1*y2 - y1*x2)*(y3 - y4)-(y1 - y2)*(x3*y4 - y3*x4)
    let d = (x1 - x2)*(y3 - y4)-(y1 - y2)*(x3 - x4)
    if d == 0 {
      return none
    }
    return (nx / d, ny / d, 0)
  }
  let pt = lli8(a.at(0), a.at(1), b.at(0), b.at(1),
                c.at(0), c.at(1), d.at(0), d.at(1))
  if pt != none {
    let on-line(pt, a, b) = {
      let (x, y, ..) = pt
      let epsilon = util.float-epsilon
      let mx = calc.min(a.at(0), b.at(0)) - epsilon
      let my = calc.min(a.at(1), b.at(1)) - epsilon
      let Mx = calc.max(a.at(0), b.at(0)) + epsilon
      let My = calc.max(a.at(1), b.at(1)) + epsilon
      return mx <= x and Mx >= x and my <= y and My >= y
    }
    if ray or (on-line(pt, a, b) and on-line(pt, c, d)) {
      let t = {
        if calc.abs(b.at(0) - a.at(0)) > 0 {
          (pt.at(0) - a.at(0))/(b.at(0) - a.at(0))
        } else if calc.abs(b.at(1) - a.at(1)) > 0 {
          (pt.at(1) - a.at(1))/(b.at(1) - a.at(1))
        } else {
          0.
        }
      }
      return (pt, t)
    }
  }
}

/// Identical to `cetz.intersection.line-cubic` but returns
/// an array of pairs `(pt, t)` of points and their t parameter
/// along the cubic bezier curve.
#let line-cubic(la, lb, s, e, c1, c2, ray: false) = {
  // Based on:
  //   http://www.particleincell.com/blog/2013/cubic-line-intersection/
  // with some rounding improvements
  let a = lb.at(1) - la.at(1)
  let b = la.at(0) - lb.at(0)
  let c = la.at(0) * (la.at(1) - lb.at(1)) + la.at(1) * (lb.at(0) - la.at(0))

  /// Get cubic bezier function coefficients
  let _cubic-coeff(a, b, c, d) = (
    -a + 3*b - 3*c + d,
    3*a - 6*b + 3*c,
    -3*a +3*b,
    a)

  let x-coeff = _cubic-coeff(s.at(0), c1.at(0), c2.at(0), e.at(0))
  let y-coeff = _cubic-coeff(s.at(1), c1.at(1), c2.at(1), e.at(1))

  let roots = _cubic-roots(a * x-coeff.at(0) + b * y-coeff.at(0),
                           a * x-coeff.at(1) + b * y-coeff.at(1),
                           a * x-coeff.at(2) + b * y-coeff.at(2),
                           a * x-coeff.at(3) + b * y-coeff.at(3) + c)

  let pts = ()
  for t in roots {
    let pt = cubic-point(s, e, c1, c2, t)
    if ray {
      pts.push(pt)
    } else {
      let s = if calc.abs(lb.at(0) - la.at(0)) >= 1e-6 {
        (pt.at(0) - la.at(0)) / (lb.at(0) - la.at(0))
      } else {
        (pt.at(1) - la.at(1)) / (lb.at(1) - la.at(1))
      }
      if s >= 0 and s <= 1 {
        pts.push(pt)
      }
    }
  }
  return pts.zip(roots)
}


/// Identical to `cetz.intersection.line-path` but returns
/// an array of pairs `(pt, (subpath-i, segment-i, t))` of each
/// intersection point and its index/location along the path/subpath/segment.
#let line-path(la, lb, path) = {
  let pt_t_pairs = ()

  for (subpath-i, (start, closed, segments)) in path.at("segments", default: ()).enumerate() {
    let origin = start
    for (segment-i, (kind, ..args)) in segments.enumerate() {
      if kind == "l" {
        let pt_t = line-line(la, lb, origin, args.last())
        if pt_t != none {
          let (pt, t) = pt_t
          pt_t_pairs.push((pt, (subpath-i, segment-i, t)))
        }
      } else if kind == "c" {
        let (c1, c2, e) = args
        pt_t_pairs += line-cubic(la, lb, origin, e, c1, c2)
          .map(((pt, t)) => (pt, (subpath-i, segment-i, t)))
      }

      origin = args.last()
    }

    if closed {
      let pt_t = line-line(la, lb, origin, start)
      if pt_t != none {
        let (pt, t) = pt_t
        pt_t_pairs.push((pt, (subpath-i, segment-i, t)))
      }
    }
  }

  return pt_t_pairs
}

/// Identical to `cetz.intersection.path-path` but returns
/// an array of pairs `(pt, (subpath-i, segment-i, t))` of each
/// intersection point and its index/location along the path/subpath/segment.
#let path-path(a, b, samples: 8) = {
  assert(is-drawable(a))
  let pt_loc_pairs = ()

  for ((start, closed, segments)) in a.at("segments", default: ()) {
    let origin = start
    for ((kind, ..args)) in segments {
      if kind == "l" {
        pt_loc_pairs += line-path(origin, args.last(), b)
      } else if kind == "c" {
        let (c1, c2, e) = args
        let line-strip = range(samples + 1).map(t => {
          cubic-point(origin, e, c1, c2, t / samples)
        })

        for i in range(1, line-strip.len()) {
          pt_loc_pairs += line-path(line-strip.at(i - 1), line-strip.at(i), b)
        }
      }

      origin = args.last()
    }

    if closed {
      pt_loc_pairs += line-path(origin, start, b)
    }
  }
  return pt_loc_pairs
}



/// Modify the given path so that it terminates at the first intersection
/// (ordered by the path parameter) encountered with the target path.
/// 
/// If `from-end` is `true`, then returns the portion of the path between
/// the last intersection and the end point, otherwise between the start
/// and the first intersection.
#let trim-drawable(
  /// Drawable to truncate, of the form `(type: "path", segments: ..)`.
  path,
  /// Cutting drawables which may intersect the drawable to truncate.
  /// -> path
  targets,
  /// If `true`, return the portion of the path after all intersections
  /// instead of before.
  from-end: false,
) = {
  if type(targets) != array { targets = (targets,) }
  let pts = targets.map(target => path-path(target, path))
    .join()
    .sorted(key: ((pt, indices)) => indices)

  if pts.len() == 0 { return path }
  let pt_info = if from-end { pts.last() } else { pts.first() }

  let (pt, (subpath-i, segment-i, t)) = pt_info

  let subpath = path.segments.at(subpath-i)
  let (origin, closed, segments) = subpath
  let prev-pt = {
    if segment-i > 0 {
      segments.at(segment-i - 1).last()
    } else {
      origin
    }
  }

  let this-segment = segments.at(segment-i)
  let new-segments = ()
  if not from-end {
    new-segments += segments.slice(0, segment-i)
    if this-segment.first() == "l" {
      new-segments.push(("l", pt.map(float)))
    } else {
      let (_, c1, c2, e) = this-segment
      let (left, right) = cetz.path-util.bezier.split(prev-pt, e, c1, c2, t)
      let (_, e, c1, c2) = left
      new-segments.push(("c", c1, c2, e))
    }
  } else {
    if this-segment.first() == "l" {
      new-segments.push(this-segment)
      origin = pt.map(float)
    } else {
      let (_ss_, c1, c2, e) = this-segment
      let (left, right) = cetz.path-util.bezier.split(prev-pt, e, c1, c2, t)
      let (s, e, c1, c2) = right
      origin = s
      new-segments.push(("c", c1, c2, e))
    }
    new-segments += segments.slice(segment-i + 1)
  }

  path.segments.at(subpath-i) = (origin, false, new-segments)
  return path
}