#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "paths.typ"
#import "nodes.typ" as Nodes
#import "debug.typ": debug-group, debug-level, get-debug

#let DEFAULT_EDGE_STYLE = (
  stroke: (thickness: 0.048em, cap: "round"),
  extrude: (0,),
  marks: (),
  mark-scale: 1,
  join: "round",
  corner-radius: 2.5pt,
  miter-limit: 4.0,
  snap-method: "trim",
  decorate: (
    kind: none,
    amplitude: 8,
    wavelength: 10,
    smooth: auto,
    shorten: 0,
  ),
  crossing-fill: white,
  crossing-thickness: 3,
)


#let draw-labels-on-path(
  ctx,
  path,
  labels,
  debug: false,
) = {
  let sample-pt(t, reverse) = {
    let (x, x-vel, x-accel) = {
      if type(t) in (int, float) {
        paths.point-on-path(ctx, path, segment: t)
      } else {
        paths.point-on-path(ctx, path, length: t)
      }
    }
    let x = cetz.util.revert-transform(ctx.transform, x)
    let x-vel = cetz.util.revert-transform(ctx.transform, x-vel)
    let x-accel = cetz.util.revert-transform(ctx.transform, x-accel)
    (x, x-vel, x-accel)
  }


  for label in labels {
    let (point, vel, accel) = sample-pt(label.pos, false)
    let tangent-angle = calc.atan2(vel.at(0), vel.at(1))

    if label.anchor != auto {
      if label.side != auto {
        utils.error(
          "label options `anchor: #0` and `side: #1` cannot be used together; one must be `auto`",
          repr(label.anchor),
          repr(label.side),
        )
      }
      // anchor is set explicitly; don't deduce anchor from side
      label.side = none
    }

    // 1. resolve label.angle to angle
    if type(label.angle) == alignment {
      label.angle = (
        tangent-angle
          - (
            right: 0deg,
            top: 90deg,
            left: 180deg,
            bottom: 270deg,
          ).at(repr(label.angle))
      )
    } else if label.angle == auto {
      if calc.abs(tangent-angle) > 90deg {
        label.angle = tangent-angle + 180deg
      } else {
        label.angle = tangent-angle
      }
      if label.anchor == auto {
        label.anchor = utils.angle-to-anchor(label.angle)
      }
    }
    assert(type(label.angle) == angle)

    // 2. resolve label.side to boolean or none/center and resolve anchor
    if label.side == auto {
      // automatically choose label side so that...
      let is-curving = cetz.vector.len(accel) > 1e-5
      if is-curving {
        // ...if the edge is curved, label is on the outer side
        label.side = accel.at(0) * vel.at(1) - accel.at(1) * vel.at(0) > 0
        // formula comes from sign of z-coord of cross product
      } else {
        // ...if edge is straight, label is generally north of it
        label.side = top
      }
    }

    if type(label.side) == alignment {
      let v = (0, 0)
      if label.side.x == right { v.first() = +1 }
      if label.side.x == left { v.first() = -1 }
      if label.side.y == top { v.last() = +1 }
      if label.side.y == bottom { v.last() = -1 }
      if v == (0, 0) {
        if label.side == alignment.start {
          label.anchor = utils.angle-to-anchor(tangent-angle)
        } else if label.side == alignment.end {
          label.anchor = utils.angle-to-anchor(tangent-angle + 180deg)
        } else {
          label.anchor = "center"
        }
        label.side = none
      } else {
        label.side = utils.wrap-angle-180(calc.atan2(..v) - tangent-angle) > -1deg
      }
    }

    if type(label.side) == bool {
      let delta = if label.side { -90deg } else { +90deg }
      label.anchor = utils.angle-to-anchor(tangent-angle + delta - label.angle)
    }

    if label.fill == auto {
      label.fill = if label.anchor == "center" { white }
    }

    cetz.draw.content(
      point,
      box(
        label.body,
        outset: 2pt,
        inset: 0pt,
        fill: label.fill,
        stroke: if debug-level(debug, "edge.label") { purple.transparentize(50%) + 0.25pt },
      ),
      anchor: label.anchor,
      angle: label.angle,
      padding: label.sep,
      name: "label",
    )

    if debug-level(debug, "edge.label") {
      debug-group({
        cetz.draw.circle(point, radius: 1pt, fill: purple.transparentize(50%), stroke: none)
        // cetz.draw.rect("label.north-east", "label.south-west", stroke: purple.transparentize(50%) + 0.25pt)
      })
    }
  }
}


#let process-edge-drawable(ctx, edge) = {
  let objs = (edge.draw)(edge.vertices)
  if objs.len() != 1 { utils.error("edge.draw should return a single CeTZ object") }

  let drawables = cetz.process.element(ctx, objs.first()).drawables
  if drawables.len() != 1 { utils.error("edge.draw should return a single drawable") }

  return drawables.first()
}


#let apply-decorations(
  ctx,
  element,
  stroke: 1pt,
  kind: "wave",
  smooth: 1,
  shorten: .5,
  amplitude: 8,
  wavelength: 10,
) = {
  if kind == none {
    return element
  }
  let kinds = (
    wave: cetz.decorations.wave,
    zigzag: cetz.decorations.zigzag,
    coil: cetz.decorations.coil,
    square: cetz.decorations.square,
    "~": cetz.decorations.wave,
  )
  if kind not in kinds {
    utils.error("unknown decoration kind #0. Try #..1", repr(kind), kinds.keys())
  }
  let decorate-fn = kinds.at(kind)

  // sigmoid of x/d
  let σ(x, d) = {
    if d == 0 { float(x >= 0) } else if x / d > 10 { return 1. } else {
      let e = calc.exp(x / d)
      e / (1 + e)
    }
  }

  let unit-length = ctx.length.to-absolute()
  let thickness = utils.get-thickness(stroke).to-absolute()

  let (drawables,) = cetz.process.element(ctx, element.first())

  let total-length = cetz.path-util.length(drawables.first().segments)

  let amplitude = utils.to-length(amplitude, units-of: thickness)

  let wavelength = utils.to-length(wavelength, units-of: thickness, ratios-of: total-length, to-float: unit-length)

  let (t0-short, t1-short) = utils
    .as-pair(shorten)
    .map(utils.to-length.with(ratios-of: total-length, units-of: wavelength / total-length, to-float: unit-length))
  let (t0-smooth, t1-smooth) = utils
    .as-pair(smooth)
    .map(utils.to-length.with(ratios-of: total-length, units-of: wavelength / total-length, to-float: unit-length))

  // https://www.desmos.com/CALCULATOR/dz7ju1havq
  let amplitude-fn(t) = {
    t = float(t)
    let c = 2
    (
      amplitude
        * σ(c * (2 * (t - t0-smooth) - t0-short), t0-smooth)
        * σ(c * (2 * (1 - t - t1-smooth) - t1-short), t1-smooth)
    )
  }

  decorate-fn(
    element,
    amplitude: amplitude-fn,
    stroke: stroke,
    segment-length: wavelength,
  )
}


/// Apply edge effects to a CeTZ drawable.
/// These effects include path extrusion and shortening,
/// mark and label placement, and edge snapping (cutting
/// the path at its intersections with target drawables).
#let apply-edge-effects(
  ctx,
  drawable,
  stroke: 1pt,
  labels: (),
  marks: (),
  extrude: (0,),
  shorten: (0, 0),
  ..extra-path-effect-args,
  debug: false,
  decorate: none,
  crossing-stroke: none,
) = {
  assert(paths.is-drawable(drawable))

  shorten = shorten.map(s => cetz.util.resolve-number(ctx, s))
  if shorten.any(s => s != 0) {
    let path = drawable.segments
    drawable.segments = cetz.path-util.shorten-to(path, shorten)
  }

  let (shorten-start, shorten-end, marks) = Marks.draw-marks-on-path(
    ctx,
    drawable.segments,
    marks,
    stroke: stroke,
    extrude: extrude,
    debug: debug,
  )

  let path = paths._path-effect(
    ctx,
    (drawable,),
    shorten-start: shorten-start,
    shorten-end: shorten-end,
    stroke: stroke,
    fill: none,
    extrude: extrude,
    ..extra-path-effect-args,
  )

  if decorate != none {
    path = apply-decorations(
      ctx,
      path,
      stroke: stroke,
      kind: decorate.kind,
      amplitude: decorate.amplitude,
      wavelength: decorate.wavelength,
      smooth: decorate.smooth,
      shorten: decorate.shorten,
    )
  }


  if crossing-stroke != none {
    (ctx => {
      let drawables = cetz.process.many(ctx, path).drawables
        .map(drawable => {
          drawable.stroke = crossing-stroke
          drawable
        })
      (ctx: ctx, drawables: drawables)
    },)
  }

  path

  marks

  draw-labels-on-path(ctx, drawable.segments, labels, debug: debug)
}


#let find-snapping-drawables(ctx, nodes, edge) = {
  let node-drawables(node, outset) = {
    if outset == auto { outset = node.style.outset }
    node.style.extrude = (outset,)
    node.name = none
    node.body = none
    node.style.stroke = purple.transparentize(50%) + 0.5pt
    let objs = Nodes.draw-node-at(node, node.pos, debug: false)
    return cetz.process.many(ctx, objs).drawables
  }

  return (0, -1).map(i => {
    // first and last index
    let snap-to = edge.snap-to.at(i)
    let pos = edge.vertices.at(i)
    let outset = edge.style.outset.at(i)

    let target-drawables
    if type(snap-to) == str {
      // look up fletcher or cetz node by name
      let node = nodes.find(n => n.name == snap-to)
      if node != none {
        target-drawables = node-drawables(node, outset)
      } else if snap-to in ctx.nodes {
        target-drawables = ctx.nodes.at(snap-to).drawables
      } else {
        utils.error("in edge `snap-to`, node #0 not found", repr(snap-to))
      }
    } else if snap-to == auto {
      // find fletcher nodes nearby
      let dist(node) = cetz.vector.dist(node.pos, pos)
      let node = nodes.filter(n => dist(n) <= cetz.vector.len(n.size) / 2).sorted(key: dist).at(0, default: none)
      if node != none {
        target-drawables = node-drawables(node, outset)
      }
    }

    return target-drawables
  })
}


#let apply-edge-snapping(ctx, edge, drawable, snap-to) = {
  let old-drawable = drawable

  let (snap-start, snap-end) = snap-to
  let (method-start, method-end) = edge.style.snap-method

  if snap-start != none and method-start == "move" {
    let pts = paths.intersections(drawable, snap-start)
    if pts.len() > 0 {
      let (pt, index) = pts.first()
      edge.vertices.first() = cetz.util.revert-transform(ctx.transform, pt)
      drawable = process-edge-drawable(ctx, edge)
    }
  }

  if snap-end != none and method-end == "move" {
    let pts = paths.intersections(old-drawable, snap-end)
    if pts.len() > 0 {
      let (pt, index) = pts.last()
      edge.vertices.last() = cetz.util.revert-transform(ctx.transform, pt)
      drawable = process-edge-drawable(ctx, edge)
    }
  }

  if snap-start != none and method-start == "trim" {
    drawable = paths.trim-to-intersection(drawable, snap-start, trim: "start")
  }

  if snap-end != none and method-end == "trim" {
    drawable = paths.trim-to-intersection(drawable, snap-end, trim: "end")
  }

  return drawable
}


#let draw-edge(ctx, edge) = {
  let drawable = process-edge-drawable(ctx, edge)

  if debug-level(edge.debug, "edge.snap") {
    // show where edge would be drawn without any snapping
    debug-group({
      (
        ctx => (
          ctx: ctx,
          drawables: drawable
            + (
              stroke: (thickness: 0.5pt, paint: purple.transparentize(50%)),
              fill: none,
            ),
        ),
      )
    })
  }

  let snap-objects = find-snapping-drawables(ctx, ctx.shared-state.fletcher.nodes, edge)

  let drawable = apply-edge-snapping(ctx, edge, drawable, snap-objects)


  let crossing-stroke
  if edge.crossing == true {
    // panic()
    crossing-stroke = stroke((
      paint: edge.style.crossing-fill,
      thickness: utils.to-length(
        edge.style.crossing-thickness,
        units-of: edge.style.stroke.thickness,
      )
    ))
  }


  let scene = apply-edge-effects(
    ctx,
    drawable,
    stroke: edge.style.stroke,
    extrude: edge.style.extrude,
    shorten: edge.style.shorten,
    marks: edge.style.marks,
    decorate: edge.style.decorate,
    labels: edge.labels,
    corner-radius: edge.style.corner-radius,
    join: edge.style.join,
    miter-limit: edge.style.miter-limit,
    debug: edge.debug,
    crossing-stroke: crossing-stroke,
  )

  if debug-level(edge.debug, "edge.snap") {
    // visualise the drawables that the edge is supposed to snap to
    debug-group((
      ctx => {
        let (snap-start, snap-end) = snap-objects
        let drawables = ()
        if snap-start != none and debug-level(edge.debug, "edge.snap.from") {
          drawables += snap-start.map(path => {
            path.stroke = green.transparentize(30%)
            path.fill = green.transparentize(80%)
            path
          })
        }
        if snap-end != none and debug-level(edge.debug, "edge.snap.to") {
          drawables += snap-end.map(path => {
            path.stroke = red.transparentize(30%)
            path.fill = red.transparentize(80%)
            path
          })
        }
        return (
          ctx: ctx,
          drawables: drawables,
        )
      },
    ))
  }

  if edge.layer != 0 {
    scene = cetz.draw.on-layer(edge.layer, scene)
  }
  scene
}

#let remove-no-flip-coords(ctx, c) = {
  if type(c) == dictionary and "no-flip" in c {
    let (no-flip, ..rest) = c
    rest
  } else {
    c
  }
}

#let _edge(
  vertices: (),
  style: (:),
  labels: (),
  snap-to: (auto, auto),
  name: none,
  draw: vertices => none,
  layer: 0,
  crossing: false,
  debug: auto,
) = cetz.draw.get-ctx(ctx => {
  if "fletcher" not in ctx.shared-state {
    ctx.shared-state.fletcher = (
      pass: none,
      nodes: (),
      edges: (),
    )
  }
  let fletcher-ctx = ctx.shared-state.fletcher

  let edge-data = (
    class: "edge",
    vertices: vertices,
    style: style.pairs().filter(((k, v)) => v != auto).to-dict(),
    labels: labels,
    snap-to: snap-to,
    name: name,
    draw: draw,
    layer: layer,
    crossing: crossing,
    debug: get-debug(ctx, debug),
  )

  // resolve styles
  let ctx-style = ctx.style.at("edge", default: (:))
  if "stroke" in ctx-style {
    // strokes must be dictionaries to enable folding
    ctx-style.stroke = utils.stroke-to-dict(ctx-style.stroke)
  }
  edge-data.style = cetz.styles.resolve(
    ctx-style,
    base: DEFAULT_EDGE_STYLE,
    merge: edge-data.style,
  )

  // resolve marks
  edge-data.style.marks = edge-data.style.marks.map(mark => {
    mark.size *= float(edge-data.style.mark-scale)
    Marks.resolve-mark(mark)
  })

  // validate some styles
  edge-data.style.snap-method = utils
    .as-pair(edge-data.style.snap-method)
    .map(m => {
      let options = ("trim", "move")
      if m not in options { utils.error("Snapping method must be #..1; got #0", repr(m), options) }
      m
    })

  let mark-0 = edge-data.style.marks.find(m => m.pos == 0)
  let mark-1 = edge-data.style.marks.find(m => m.pos == 1)
  if edge-data.style.decorate.smooth == auto {
    edge-data.style.decorate.smooth = (
      if mark-0 == none { 0 } else { 1.0 },
      if mark-1 == none { 0 } else { 1.0 },
    )
  }
  if edge-data.style.decorate.shorten == auto {
    panic()
    let t = edge-data.style.stroke.thickness
    edge-data.style.decorate.shorten = (
      if mark-0 == none { 0 } else { -(0 + 2 * mark-0.tip-hang) * t },
      if mark-1 == none { 0 } else { -(0 + 2 * mark-1.tip-hang) * t },
    )
  }


  // if edge appears in a flexigrid, interpret coordinates in uv system by default
  if fletcher-ctx.pass == "final" {
    edge-data.vertices = edge-data.vertices.map(utils.interpret-as-uv)
  } else {

    // resolve special no-flip marks
    edge-data.vertices = edge-data.vertices.map(remove-no-flip-coords.with(ctx))
  }


  // resolve auto vertices to prev/next node
  let (first, .., last) = edge-data.vertices
  if fletcher-ctx.pass == "final" {
    let i = fletcher-ctx.current.node
    if first == auto and i > 0 {
      first = fletcher-ctx.nodes.at(i - 1).pos
    }
    if last == auto and i < fletcher-ctx.nodes.len() {
      last = fletcher-ctx.nodes.at(i).pos
    }
  }

  // give reasonable defaults rather than panic
  if first == auto { first = () }
  if last == auto { last = (rel: (1, 0)) }
  edge-data.vertices.first() = first
  edge-data.vertices.last() = last

  // snap to cetz nodes if first/last vertex is a node name
  if type(first) == str and edge-data.snap-to.first() == auto {
    if first in ctx.nodes { edge-data.snap-to.first() = first }
  }
  if type(last) == str and edge-data.snap-to.last() == auto {
    if last in ctx.nodes { edge-data.snap-to.last() = last }
  }

  // resolve vertex coordinate expressions
  // discard ctx because we do not want to update ctx.prev.pt
  // edge vertices should never affect nodes with relative positions
  let (_, ..vertices) = cetz.coordinate.resolve(ctx, ..edge-data.vertices)
  edge-data.vertices = vertices

  if "current" in fletcher-ctx {
    ctx.shared-state.fletcher.current.edge += 1
  }
  if fletcher-ctx.pass != "final" {
    ctx.shared-state.fletcher.edges.push(edge-data)
  }

  if fletcher-ctx.pass == "layout" {
    // for the layout pass, we only need to identify nodes/edges/anchors
    // so we skip path effects, marks, etc for performance
    (edge-data.draw)(edge-data.vertices)
  } else {
    draw-edge(ctx, edge-data)
  }
})



#let interpret-marks-arg(marks) = {
  if marks == none { (marks: ()) } else if type(marks) == array {
    (marks: Marks.interpret-marks(marks))
  } else if type(marks) in (str, symbol) {
    let (marks, options) = parsing.parse-mark-shorthand(marks)
    (marks: Marks.interpret-marks(marks), ..options)
  } else {
    utils.error("could not interpret marks argument: #0", marks)
  }
}

#let EDGE_KINDS = (
  arc: (
    required: ("bend",),
    optional: (:),
    n-vertices: 2,
    draw: ((bend,), (a, b)) => {
      let perp-dist = if type(bend) == angle {
        let sin-bend = calc.sin(bend)
        if calc.abs(sin-bend) < 1e-3 { return cetz.draw.line(a, b) }
        let half-chord-len = cetz.vector.dist(a, b) / 2
        half-chord-len * (1 - calc.cos(bend)) / sin-bend
      } else {
        bend
      }
      let midpoint = (a: (a, 50%, b), b: a, number: perp-dist, angle: -90deg)
      cetz.draw.merge-path(cetz.draw.arc-through(a, midpoint, b))
    },
  ),
  bezier-cubic: (
    required: ("from", "to"),
    optional: (:),
    n-vertices: 2,
    draw: ((from, to), (a, b)) => {
      let as-coord(x) = {
        if type(x) == angle { (x, 1) } else { x }
      }
      cetz.draw.bezier(a, b, (rel: as-coord(from), to: a), (rel: as-coord(to), to: b))
    },
  ),
  bezier-from: (
    required: ("from",),
    optional: (:),
    n-vertices: 2,
    draw: ((from,), (a, b)) => {
      if type(from) == angle { from = (from, 1) }
      cetz.draw.bezier(a, b, (rel: from, to: a))
    },
  ),
  bezier-to: (
    required: ("to",),
    optional: (:),
    n-vertices: 2,
    draw: ((to,), (a, b)) => {
      if type(to) == angle { to = (to, 1) }
      cetz.draw.bezier(a, b, (rel: to, to: b))
    },
  ),
  bezier-through: (
    required: ("through",),
    optional: (:),
    n-vertices: 2,
    draw: ((through,), (a, b)) => {
      cetz.draw.bezier-through(a, through, b)
    },
  ),
  loop: (
    required: (),
    optional: (loop: 0.3, loop-angle: 0deg),
    draw: ((loop, loop-angle), (a, ..)) => {
      let angle = utils.thing-to-angle(loop-angle) + 180deg
      cetz.draw.arc(a, radius: loop, start: angle, delta: -360deg)
    },
  ),
  corner: (
    required: ("corner",),
    optional: (:),
    draw: ((corner,), (a, b)) => {
      if corner == "|-" {
        cetz.draw.line(a, (a, "|-", b), b)
      } else if corner == "-|" {
        cetz.draw.line(a, (a, "-|", b), b)
      } else if corner == "-|-" {
        let mid = (a, 50%, b)
        cetz.draw.line(a, (a, "-|", mid), (mid, "|-", b), b)
      } else if corner == "|-|" {
        let mid = (a, 50%, b)
        cetz.draw.line(a, (a, "|-", mid), (mid, "-|", b), b)
      } else {
        utils.error("edge shape `corner` accepts one of #..0; got #1", ("-|", "|-", "-|-", "|-|"), repr(corner))
      }
    },
  ),
)


#let determine-edge-kind(named, options) = {
  let kind = none
  let named-arg-suggestion = none

  for (spec-kind, spec) in EDGE_KINDS {
    let has-all-required = spec.required.all(n => n in named)
    let has-some-optional = spec.optional.keys().any(n => n in named)

    if spec.required.len() > 0 and has-all-required {
      kind = spec-kind
      break
    } else if has-all-required and has-some-optional {
      kind = spec-kind
      break
    } else if spec.required.any(n => n in named) {
      named-arg-suggestion = (kind: kind, args: spec.required)
    }
  }


  if kind != none {
    let spec = EDGE_KINDS.at(kind)

    let draw-args = (:)

    for arg in spec.required { draw-args.insert(arg, named.remove(arg)) }

    for (arg, default) in spec.optional {
      if arg in named { draw-args.insert(arg, named.remove(arg)) } else { draw-args.insert(arg, default) }
    }

    if options.draw != auto {
      utils.error({
        "edge option `draw` must be `auto` when used with "
        spec.required.map(repr).join(", ")
      })
    }
    options.draw = spec.draw.with(draw-args)

    if "n-vertices" in spec {
      if options.vertices.len() != spec.n-vertices {
        utils.error({
          kind
          " edges (with "
          spec.required.map(repr).join(", ")
          " arguments) require exactly "
          repr(spec.n-vertices)
          " vertices; got "
          repr(options.vertices)
        })
      }
    }
  }

  // any left over named arguments are unrecognised
  if named.len() > 0 {
    let hint = if named-arg-suggestion != none {
      " For "
      named-arg-suggestion.kind
      " edges, also specify "
      named-arg-suggestion.args.filter(n => n not in named).map(repr).join(", ", last: " and ")
      "."
    }
    utils.error("Unknown edge arguments #..0." + hint, named.keys())
  }

  if options.draw == auto {
    options.draw = vertices => cetz.draw.line(..vertices)
  }

  return (draw: options.draw)
}

// consumes `label-*` named arguments and validates
#let interpret-label-args(named, options) = {
  let default-spec = (
    body: none,
    pos: 50%,
    side: auto,
    sep: 3pt,
    angle: 0deg,
    fill: auto,
    anchor: auto,
  )

  let label-args = named.keys().filter(arg => arg.starts-with("label-"))
  for arg in label-args {
    let suffix = arg.trim("label-", at: start)
    if suffix in default-spec {
      default-spec.at(suffix) = named.remove(arg)
    } else {
      let possible-options = default-spec.keys().map(o => "label-" + o)
      utils.error("invalid option #0. Try #..1", repr(arg), possible-options)
    }
  }


  let as-label-spec(x) = {
    if x == none {
      return none
    } else if type(x) == dictionary {
      let spec = default-spec
      for (k, v) in x {
        if k in spec { spec.at(k) = v } else {
          utils.error("invalid label property #0. Try: #..1", repr(k), spec.keys())
        }
      }
      return spec
    } else {
      return as-label-spec((body: x))
    }
  }


  let spec = utils.one-or-array(options.label).map(as-label-spec).filter(l => l != none)


  return (named, spec)
}

#let interpret-decorate-arg(it) = {
  if it in (auto, none) { return it }
  if type(it) == str { it = (kind: it) }
  if type(it) != dictionary {
    utils.error("edge `decorate` option should be a string, dictionary or none; got #0", it)
  }
  let valid = DEFAULT_EDGE_STYLE.decorate.keys()
  let invalid = it.keys().filter(k => k not in valid)
  if invalid.len() > 0 {
    utils.error("unknown key `#0` in edge `decorate` option: Try #..1", invalid.first(), valid)
  }
  return it
}

/// Draw a path with arrow marks, labels, and automatic snapping to nodes.
#let edge(
  /// An edge's positional arguments may specify:
  /// - the edge's @edge.vertices, each given as a CeTZ coordinate;
  /// - the CeTZ path to apply edge marks, styles, and labels to;
  /// - the edge's @edge.marks, e.g., `"->"` or `"solid=/=solid"`;
  /// - the body content of an edge @edge.label, e.g., `$f$`; or
  /// - some other style flags (#fletcher.edges.parsing.EDGE_FLAGS.keys().map(raw).join[, ]).
  ///
  /// Vertex coordinates come first but are optional:
  ///
  /// ```typc
  /// edge(from, to, ..) // explicit start and end
  /// edge(to, ..) == edge(auto, to, ..) // start from previous node
  /// edge(..) == edge(auto, auto, ..) // between previous and next nodes
  /// edge(from, v1, v2, ..vs, to, ..) // multiple vertices
  /// edge(from, "->", to) // for two vertices, marks can go in the middle
  /// ```
  ///
  /// Vertices after the first one can be relative coordinate shorthand
  /// strings containing the characters
  /// ${#"lrudtbnesw".clusters().map(raw).join($, $)}$ or commas, e.g., `edge((0,0), "u,rr,d")`.
  ///
  /// If applying edge effects to a CeTZ path, no vertices should be given and the path should be the first argument:
  ///
  /// ```typc
  /// edge(cetz.draw.bezier(..), "<->") // add marks to a cetz path
  /// ```
  ///
  /// If given as positional arguments, an edge's @edge.marks and @edge.label
  /// are disambiguated based on their types.
  /// For example, the following are equivalent:
  /// ```typc
  /// edge(.., $f$, "->")
  /// edge(.., "->", $f$)
  /// edge(.., $f$, marks: "->")
  /// edge(.., "->", label: $f$)
  /// edge(.., label: $f$, marks: "->")
  /// ```
  /// ->
  ..args,
  /// Array of coordinates for the edge.
  ///
  /// Vertices can also be specified as leading positional arguments
  /// (so `edge((0,1), (1,1), $f$, ..)` is the same as `edge($f$, vertices: ((0,1), (1,1)), ..)`).
  /// -> array
  vertices: (),
  /// Marks or arrows to draw along the edge.
  ///
  /// TODO
  marks: (),
  /// Mark size multiplier.
  ///
  /// The `size` parameter of each mark is multiplied by the mark scale before being drawn.
  ///
  /// This is an edge style that can also be set using `diagram(mark-scale: ..)` or `cetz.draw.set-style(edge: (mark-scale: ..))`.
  ///
  /// -> number | percent | auto
  mark-scale: auto,
  /// Content to place along the edge.
  ///
  /// ```example
  /// #diagram(edge("->", $f$))
  /// ```
  ///
  /// The label body may also be given as a positional argument.
  /// ```typc
  /// edge(.., [Label])
  /// edge(.., label: [Label])
  /// ```
  /// Label options can be specified with a dictionary,
  /// or as named arguments by adding `label-` as a prefix .
  /// For example, the following are the same:
  /// ```typc
  /// edge(.., label: (body: [Label], pos: 25%))
  /// edge(.., [Label], label-pos: 25%)
  /// ```
  /// Possible label options are:
  /// - `body`: the content to draw
  /// - `angle`: orientation of the label body (see @edge.label-angle)
  /// - `pos`: the label's position along the edge path (see @edge.label-pos)
  /// - `sep`: padding between the label's body and the path (see @edge.label-sep)
  /// - `side`: which side of the edge to place the body (see @edge.label-side)
  /// - `anchor`: the CeTZ anchor to use for label body (see @edge.label-anchor)
  ///
  /// Multiple labels can be specified with an array:
  /// ```typc
  /// edge(.., label: ([First label], (body: [Second label], pos: 25%)))
  /// ```
  ///
  /// -> content | dictionary | array
  label: none,
  /// Position along the edge path to place labels.
  ///
  /// #frame-row(..(0%, 25%, 50%, 75%, 100%).map(p => fletcher.diagram(
  ///   spacing: 2cm,
  ///   edge((0,0), (1,0), [#p], "->", label-pos: p))
  /// ))
  ///
  /// This can be a `ratio`, relative to the total path length,
  /// or a `float` whose integer part refers to the segment number and
  /// whose fractional part interpolates along the segment (see @point-on-path).
  ///
  /// ```example
  /// #diagram({
  ///   edge((0,0), (1,1), (2,1), (2,0), "->", label: (
  ///     (body: [1st], pos: 0.5),
  ///     (body: [2nd], pos: 1.5),
  ///     (body: [3rd], pos: 2.5, side: right),
  ///   ))
  /// })
  /// ```
  ///
  /// This can be given as an _edge argument_ like `edge(.., $f$, label-pos: 50%)` or as a @edge.label option like `edge(.., label: (body: $f$, pos: 50%))`.
  ///
  /// -> ratio | number | length
  label-pos: 50%,
  /// Which side of the edge to place the label on.
  ///
  /// If `auto`, the label is placed roughly above straight edges, or on the outside of curved edges.
  ///
  /// An alignment (e.g., `top`, `left`, `top + left`) means place the label beside the edge to whichever side is nearer that direction.
  /// If given as an alignment, the side may flip depending on the edge's angle.
  ///
  /// If `true`, the label is placed above the edge assuming it goes left to right;
  /// `false` is the opposite side.
  /// In these cases, the side never flips depending on the edge's angle.
  ///
  /// If `center` or `none`, the label is placed directly over the edge, and the label fill defaults to white.
  ///
  /// The special alignment values `start` and `end` place the label before or after a point, travelling along the edge. This works best when used like `(pos: 0%, side: start)` or `(pos: 100%, side: end)`.
  /// ```example
  /// #diagram(edge((0,0), "->", (1,1), label: (
  ///   (body: `start`,  side: start,  pos: 0%),
  ///   (body: `left`,   side: left,   pos: 0%),
  ///   (body: `right`,  side: right,  pos: 0%),
  ///   (body: `center`, side: center, pos: 50%),
  ///   (body: `end`,    side: end,    pos: 100%),
  ///   (body: `top`,    side: top,    pos: 100%),
  ///   (body: `bottom`, side: bottom, pos: 100%),
  /// )))
  /// ```
  ///
  /// This can be given as an _edge argument_ like `edge(.., $f$, label-side: top)` or as a @edge.label option like `edge(.., label: (body: $f$, side: top))`.
  ///
  /// -> auto | none | center | top | bottom | left | right | start | end
  label-side: auto,
  /// Separation between label body and the edge.
  ///
  /// This can be given as an _edge argument_ like `edge(.., $f$, label-sep: 3pt)` or as a @edge.label option like `edge(.., label: (body: $f$, sep: 3pt))`.
  /// -> length
  label-sep: 3pt,
  label-fill: auto,
  /// Angle of the label's body.
  ///
  /// A positive angle goes anticlockwise, with `0deg` being upright.
  ///
  /// An alignment (e.g., `top`, `right`) means to rotate the label with the
  /// edge's direction, such that the label is upright along edges going in
  /// that direction.
  ///
  /// If `auto`, the best of `left` or `right` is chosen; that is,
  /// the label is rotated to be tangent to the edge and roughly the right way up.
  ///
  /// #frame-row(..(0deg, 90deg, auto, right, top, bottom).map(angle => {
  ///   diagram(edge((0,1), (2,0), "->", [#angle], label-angle: angle))
  /// }).map(align.with(bottom)))
  ///
  /// This can be given as an _edge argument_ like `edge(.., $f$, label-angle: auto)` or as a @edge.label option like `edge(.., label: (body: $f$, angle: auto))`.
  ///
  /// -> angle | auto | top | bottom | left | right
  label-angle: 0deg,
  /// The CeTZ anchor to use for the label content.
  ///
  /// If `auto`, the anchor is automatically chosen depending on @edge.label-side and the edge's angle.
  /// This must be `auto` if the `side` option is set.
  ///
  /// -> anchor
  label-anchor: auto,
  /// Names or coordinates of nodes or CeTZ objects to snap the edge's ends to.
  ///
  /// This can be `none` to disable snapping or `auto` to detect nearby nodes.
  /// A pair such as `(none, auto)` can be used to control snapping at each end independently.
  /// 
  /// *@edge.debug options:* You can use the `debug: "edge.snap"` option to see the edge's path before snapping is applied.
  /// Additionally, the debug options `"edge.snap.from"` and `"edge.snap.to"` highlight the nodes that are ultimately snapped to.
  /// 
  /// -> none | auto | pair
  snap-to: (auto, auto),
  /// When an edge snaps to an object's outline, the edge can be shifted in two ways:
  /// one method is to shorten the edge to the point where it meets
  /// the object (the `"trim"` method); the other method is to move the edge's end vertex to the edge
  /// of the object (the `"move"` method).
  ///
  /// You can pass a pair such as `("trim", "move")` to control the methods for the start and end of the edge independently.
  ///
  /// ```example
  /// #diagram(
  ///   debug: "edge.snap",
  ///   node-fill: yellow,
  ///   node-shape: circle,
  ///   node((0,0), [Snapping]),
  ///   edge("->", `trim`, bend: +90deg, snap-method: "trim"),
  ///   edge("->", `move`, bend: -90deg, snap-method: "move"),
  ///   node((1,0), [Method]),
  /// )
  /// ```
  ///
  /// -> "trim" | "move" | pair
  snap-method: auto,
  /// Gap between the end of the edge and connected nodes.
  ///
  /// Similar to @node.outset, but specific to the edge instead of
  /// the target node.
  /// Can be a single length or a pair of lengths `(from, to)` to control the
  /// outset at either end.
  /// 
  /// ```example
  /// #diagram(
  ///   node-fill: teal,
  ///   node((0,0), [A], <a>),
  ///   node((1,0), [B], <b>),
  ///   edge(<a>, "<->", <b>, bend: +60deg, [No outset]),
  ///   edge(<a>, "<->", <b>, bend: -60deg, outset: 5pt, [Outset]),
  /// )
  /// ```
  ///
  /// See also @edge.shorten.
  /// -> length | pair
  outset: auto,
  /// Distance to shorten the edge at either end.
  ///
  /// If a length is given, the edge is shortened at both ends.
  /// A pair of lengths `(start, end)` controls shortening at either end
  /// of the edge independently.
  ///
  /// See also @edge.outset.
  /// -> length | number | array
  shorten: 0,
  name: none,
  stroke: auto,
  dash: auto,
  /// Draw a separate stroke for each extrusion offset to
  /// obtain a multi-stroke effect. Offsets may be numbers
  /// (specifying multiples of the stroke's thickness) or lengths.
  ///
  /// #frame-row(..(
  ///     (0,),
  ///     (-1.5,+1.5),
  ///     (-2,0,+2),
  ///     (-.5em,),
  ///     (0, 5pt),
  ///   ).map(e => {
  ///   diagram(edge(
  ///     (0, 0), (1, 0), [#e], "|->",
  ///     extrude: e, stroke: 1pt, label-sep: 1em
  ///   ))
  /// }))
  ///
  /// Notice how the strokes terminate on the marks properly.
  /// This is defined by the `cap-offset` option of the marks.
  /// TODO
  /// -> number | length | array
  extrude: auto,
  /// The radius of round or bevelled corners.
  /// 
  /// For extruded edges, this defines the radius of curvature of
  /// the _innermost_ stroke as you go around the bend.
  /// Note that `none`, which enables miter joins, is different from `0`.
  /// 
  /// #frame-row(..(none, 0pt, 5pt).map(it => {
  ///   	diagram(
  ///   		edge-stroke: 1pt,
  ///   		edge("r,t,rd,r", "=>", raw(repr(it)), label-pos: 60%, corner-radius: it)
  ///   	)
  ///   }))
  ///
  /// This length specifies the corner radius for right-angled bends.
  /// The actual radius is smaller for acute angles and larger for obtuse angles to balance things visually.
  /// See @path-effect.corner-radius for details.
  /// -> length | number | none
  corner-radius: auto,
  /// Apply CeTZ _path decorations_ do the edge, such as wave or zigzag effects.
  ///
  /// This can be a dictionary containing any of:
  /// - `kind`, one of `"wave"`, `"zigzag"`, `"square"` or `"coil"`
  /// - `wavelength`
  /// - `amplitude`
  /// - `shorten`, distance from ends to start effect from
  /// - `smooth`, distance over which to "ramp" the effect's amplitude for a smoother transition
  ///
  /// The `shorten` and `smooth` options can be lengths, distances (interpreted as multiples of `wavelength`) or a pair of these, controlling the values at the star and end of the path independently.
  ///
  /// ```example
  /// #diagram(
  ///   edge("ru,r", decorate: (kind: "wave", shorten: 5mm, smooth: 0)),
  /// )
  /// ```
  /// ```example
  /// #diagram(edge("rr", decorate: (
  ///   kind: "square",
  ///   amplitude: 3mm,
  ///   shorten: 0,
  ///   smooth: 2mm,
  /// )))
  /// ```
  /// ```example
  /// #diagram(
  ///   edge("ru,r", "~>", decorate: (shorten: (2, 0))),
  /// )
  /// ```
  decorate: auto,
  /// Canvas layer to draw edge on.
  ///
  /// Edges with equal layer are drawn in the order they are inserted.
  /// 
  /// #frame-row(..(0, 2).map(it => {
  ///   diagram({
  ///     node((0,0), $ times $, fill: yellow)
  ///     edge((-1,0), (+1,0), "->", raw("layer: " + repr(it)), layer: it, label-side: start, label-pos: 0%)
  ///   })
  /// }))
  /// 
  /// See also @node.layer, which is `1` by default.
  /// 
  /// -> number
  layer: 0,

  /// Draw a backdrop under the edge to give the illusion of it crossing over other lines.
  ///
  /// If `true`, draws a backdrop of color @edge.crossing-fill with a thickness @edge.crossing-stroke,
  /// which are both styles that can be set at the diagram level.
  ///
  /// ```example
  /// #diagram(
  ///   edge-stroke: 2pt,
  ///   edge((0,1), (1,0)),
  ///   edge((0,0), (1,1)),
  ///   edge((2,1), (3,0)),
  ///   edge((2,0), (3,1), crossing: true),
  /// )
  /// ```
  ///
  /// To make sure crossing lines are drawn above other lines,
  /// order them later in the diagram or use @edge.layer.
  /// -> bool
  crossing: false,
  /// Color of the "crossing" backdrop  (drawn when @edge.crossing is enabled).
  /// This should match the background of the figure to give the illusion of breaking lines below it.
  /// 
  /// #frame-row(..(white, gray, yellow).map(it => {
  ///   diagram(
  ///     edge-crossing-fill: it,
  ///     edge-stroke: 2pt,
  ///     edge((0,1), (1,0)),
  ///     edge((0,0), (1,1), "crossing"),
  ///   )
  /// }))
  /// -> color
  crossing-fill: auto,
  /// Width of the "crossing" backdrop (drawn when @edge.crossing is enabled) as a length or a multiple of the stroke's thickness.
  /// 
  /// #frame-row(..(3, 5, 5pt).map(it => {
  ///   diagram(
  ///     edge-crossing-thickness: it,
  ///     edge-stroke: 2pt,
  ///     edge((0,1), (1,0)),
  ///     edge((0,0), (1,1), "crossing"),
  ///     edge((0.5,1), (1,0.5), stroke: 1pt, "crossing"),
  ///     node((0.5, 1.5), raw(repr(it)))
  ///   )
  /// }))
  /// -> number | length
  crossing-thickness: auto,

  /// Whether to return a `metadata` object which can be placed inside equations,
  /// instead of returning an array of functions which can be inserted into a CeTZ canvas.
  ///
  /// If you often use fletcher in math mode, consider defining the shortcut:
  /// ```typ
  /// #let hom = edge.with(in-math: true)
  /// ```
  /// The `hom` edge function can be inserted into equations, like so:
  /// ```typ
  /// #diagram($x hom(|=>) & f(x)$)
  /// ```
  ///
  /// See also @node.in-math.
  /// -> bool
  in-math: false,
  draw: auto,
  debug: auto,
) = {
  let options = (
    vertices: vertices,
    marks: marks,
    mark-scale: mark-scale,
    label: label,
    snap-to: utils.as-pair(snap-to),
    snap-method: snap-method,
    outset: utils.as-pair(outset),
    shorten: utils.as-pair(shorten),
    name: if name != none { str(name) },
    stroke: stroke,
    dash: dash,
    extrude: extrude,
    layer: layer,
    crossing: crossing,
    crossing-fill: crossing-fill,
    crossing-thickness: crossing-thickness,
    draw: draw,
    decorate: decorate,
  )

  options += parsing.interpret-edge-positional-args(args.pos(), options)
  options += interpret-marks-arg(options.marks)

  if options.stroke == none {
    options.stroke = 1pt
    options.extrude = ()
  }
  options.stroke = utils.stroke-to-dict(options.stroke)
  if options.at("dash", default: auto) != auto {
    options.stroke.dash = options.dash
  }

  options.decorate = interpret-decorate-arg(options.decorate)

  let named = args.named()
  let (named, labels) = interpret-label-args(
    named
      + (
        label-pos: label-pos,
        label-side: label-side,
        label-sep: label-sep,
        label-fill: label-fill,
        label-angle: label-angle,
        label-anchor: label-anchor,
      ),
    options,
  )
  options += determine-edge-kind(named, options)


  let args = (
    vertices: options.vertices,
    style: (
      stroke: options.stroke,
      outset: options.outset,
      shorten: options.shorten,
      marks: options.marks,
      extrude: options.extrude,
      mark-scale: options.mark-scale,
      corner-radius: corner-radius,
      snap-method: options.snap-method,
      decorate: options.decorate,
      crossing-fill: options.crossing-fill,
      crossing-thickness: options.crossing-thickness,
    ),
    labels: labels,
    snap-to: options.snap-to,
    name: options.name,
    draw: options.draw,
    layer: layer,
    crossing: options.crossing,
    debug: debug,
  )

  if in-math {
    args.labels = args.labels.map(label => {
      label.body = math.equation(label.body)
      label
    })
    metadata((fletcher: "edge", args: args))
  } else {
    _edge(..args)
  }
}
