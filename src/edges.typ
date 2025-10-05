#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "paths.typ"
#import "nodes.typ" as Nodes
#import "debug.typ": debug-level, debug-group, get-debug

#let DEFAULT_EDGE_STYLE = (
  marks: (),
  stroke: (thickness: 0.048em, cap: "round"),
  extrude: (0,),
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
        paths.point-on-path(path, segment: t)
      } else {
        if type(t) == length { t = t/ctx.length }
        paths.point-on-path(path, length: t)
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

    let angle

    if label.side == auto {
      // automatically choose label side so that...
      let is-curving = cetz.vector.len(accel) > 1e-5
      if is-curving {
        // ...if the edge is curved, label is on the outer side
        angle = calc.atan2(accel.at(0), accel.at(1))
      } else {
        // ...if edge is straight, label is generally north of it
        label.side = top
      }
    }

    if type(label.side) == alignment {
      let v = (0,0)
      if label.side.x != none {
        v.first() = if label.side.x == right { +1 } else { -1 }
      }
      if label.side.y != none {
        v.last() = if label.side.y == top { +1 } else { -1 }
      }
      let a = calc.atan2(..v)
      let side = utils.wrap-angle-180(a - tangent-angle) > -1deg
      if side {
        angle = tangent-angle - 90deg
      } else {
        angle = tangent-angle + 90deg
      }
    }

    let anchor = utils.angle-to-anchor(angle)
    cetz.draw.content(point, label.body, anchor: anchor, padding: label.sep, name: "label")

    if debug-level(debug, "edge.label") {
      debug-group({
        cetz.draw.circle(point, radius: 1pt, fill: purple.transparentize(50%), stroke: none)
        cetz.draw.rect("label.north-east", "label.south-west", stroke: purple.transparentize(50%) + 0.25pt)
      })
    }
  }

}

#let draw-edge(ctx, edge) = {
  let objs = (edge.draw)(edge.vertices)

  assert(objs.len() == 1, message: "edge.draw should return single cetz element")
  let (ctx, drawables) = cetz.process.element(ctx, objs.first())
	assert.eq(drawables.len(), 1)
	let path = drawables.first().segments

  let (shorten-start, shorten-end, marks) = Marks.draw-marks-on-path(
		ctx,
		path,
		edge.style.marks,
		stroke: edge.style.stroke,
		extrude: edge.style.extrude,
		debug: edge.debug,
	)

  paths.path-effect(
    objs,
    shorten-start: shorten-start,
    shorten-end: shorten-end,
    stroke: edge.style.stroke,
    extrude: edge.style.extrude,
  )

  marks

  draw-labels-on-path(ctx, path, edge.labels, debug: edge.debug)

  // create proxy named cetz object which draws nothing but handles anchors
  (ctx => {
    let (anchors, drawables) = objs.first()(ctx)
    let get-anchors(k) = {
      if k == "default" { k = "mid" }
      anchors(k)
    }
    return (
      ctx: ctx,
      name: edge.name,
      anchors: get-anchors,
      drawables: (),
    )
  },)
  
}

#let find-anchor-by-distance(ctx, name, reference-point, near: false) = {
  let get-anchors = ctx.nodes.at(name).anchors
  let anchor-names = (get-anchors)(())

  let s = if near { -1 } else { 1 } 
  let ref = cetz.util.apply-transform(ctx.transform, reference-point)

  let all-anchors = anchor-names
    .map(get-anchors)
    .sorted(key: a => s*cetz.vector.dist(a, ref))

  let best = all-anchors.at(-1, default: ref)
  return cetz.util.revert-transform(ctx.transform, best)
}


/// Find a node that the end of an edge should snap to.
/// -> none | node
#let find-snapping-node(
  /// Array of nodes (dictionaries with `class: "node"`) -> array
  nodes,
  /// The snapping key. This can be `none` to disable snapping,
  /// a node name (`str` or `label`), or a coordinate for finding
  /// nearby nodes.
  /// -> auto | none | coord | str | label
  snap-to,
  /// Nearby nodes are found by their proximity to this coordinate.
  position,
) = {

  // snapping disabled
  if snap-to == none { return }

  // snap to node by name
  if type(snap-to) == str {
    let node = nodes.find(n => n.name == snap-to)
    if node == none { utils.error("couldn't find name #0", snap-to) }
    return node
  }

  // snap to node by proximity
  if snap-to == auto { snap-to = position }
  let dist(node) = cetz.vector.dist(node.pos, position)
  return nodes
    .filter(n => dist(n) <= cetz.vector.len(n.size)/2)
    .sorted(key: dist)
    .at(0, default: none)
}


#let get-snapping-node-anchor(node, vertex) = {
  if node.enclose != none {
    // panic(node, vertex)
  }
  vertex
}

#let draw-node-snapping-outline(node, outset) = {
  let node = node
  if outset == auto { outset = node.style.outset }
  node.style.extrude = (outset,)
  node.name = none
  node.body = none
  node.style.stroke = purple.transparentize(50%) + 0.5pt
  Nodes.draw-node-at(node, node.pos, debug: false)
}


/// Draw an edge, snapping each end to given CeTZ objects.
/// 
/// The first and last segments of the edge are tested for intersection with the
/// first and last elements of `snap-to`, respectively. If no intersections are found,
/// the first/last vertices of the edge are left as is; otherwise, they are replaced
/// with the farthest intersection from the original vertex.
#let draw-edge-with-intersection-snapping(
  ctx,
  edge,
  /// Shapes to snap the start and end of the edge to, respectively. -> (cetz, cetz)
  snap-to: (none, none),
) = {

  let edge-test-path = (edge.draw)(edge.vertices)
  let src-test-path = paths.draw-only-first-path-segment(edge-test-path)
  let tgt-test-path = paths.draw-only-last-path-segment(edge-test-path)

  cetz.draw.hide({
    cetz.draw.intersections("__src__", snap-to.at(0) + src-test-path)
    cetz.draw.intersections("__tgt__", snap-to.at(1) + tgt-test-path)
  })

  cetz.draw.get-ctx(ctx => {
    let src-snapped = find-anchor-by-distance(ctx, "__src__", edge.vertices.first())
    let tgt-snapped = find-anchor-by-distance(ctx, "__tgt__", edge.vertices.last())

    if (src-snapped == tgt-snapped) {
      // edge snapping resulted in same start and end points
      // make it so that only one end snaps, whichever one is closer
      let src-dist = cetz.vector.dist(src-snapped, edge.vertices.first())
      let tgt-dist = cetz.vector.dist(tgt-snapped, edge.vertices.last())
      if src-dist < tgt-dist {
        tgt-snapped = edge.vertices.last()
      } else {
        src-snapped = edge.vertices.first()
      }
    }

    let edge = edge
    edge.vertices.first() = src-snapped
    edge.vertices.last() = tgt-snapped
    
    draw-edge(ctx, edge)

    if debug-level(edge.debug, "edge.snap") {
      debug-group({
        cetz.draw.group({
          cetz.draw.set-style(stroke: (thickness: 0.5pt, paint: purple.transparentize(50%)))
          src-test-path
          tgt-test-path
        })
        let t = utils.get-thickness(edge.style.stroke)
        cetz.draw.circle(src-snapped, radius: t, fill: green.transparentize(50%), stroke: none)
        cetz.draw.circle(tgt-snapped, radius: t, fill: red.transparentize(50%), stroke: none)
      })
    }
  })

  (ctx => {
    ctx.nodes.remove("__src__")
    ctx.nodes.remove("__tgt__")
    return (ctx: ctx)
  },)

}

/// Draw an edge, snapping each end to given fletcher nodes.
#let draw-edge-with-snapping(edge, snapping-nodes) = {
  cetz.draw.get-ctx(ctx => {

    let ctx-edge = ctx.style.at("edge", default: (:))
    ctx-edge.stroke = utils.stroke-to-dict(ctx-edge.at("stroke", default: (:)))

    let edge = edge
    edge.style = cetz.styles.resolve(
      ctx-edge,
      base: DEFAULT_EDGE_STYLE,
      merge: edge.style,
      // root: "edge",
    )

    let snapping-outlines = snapping-nodes
      .zip(edge.style.outset)
      .map(((key, outset)) => {
        if key == none { return }
        if type(key) == str {
          panic(key)
          if key not in ctx.nodes { utils.error("couldn't find name #0", key) }
          let drawables = ctx.nodes.at(key).drawables
          return (ctx => (ctx: ctx, drawables: drawables),)
        } else if utils.is-node(key) {
          let node = key
          node.style.fill = none
          draw-node-snapping-outline(node, outset)
        }
      })

    if debug-level(edge.debug, "edge.snap") {
      debug-group(snapping-outlines.join())
    }

    let (src, .., tgt) = edge.vertices

    draw-edge-with-intersection-snapping(
      ctx,
      edge,
      snap-to: snapping-outlines,
    )
  })
}


#let _edge(
  vertices,
  style: (:),
  labels: (),
  snap-to: (auto, auto),
  name: none,
  draw: vertices => none,
  debug: auto,
) = {

  (ctx => {
    
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
      style: {
        if style.extrude != auto { (extrude: style.extrude) }
        if style.stroke != auto { (stroke: utils.stroke-to-dict(style.stroke)) }
        if style.outset != auto { (outset: style.outset) }
        if style.marks != auto { (marks: style.marks) }
      },
      labels: labels,
      snap-to: utils.as-pair(snap-to),
      name: name,
      draw: draw,
      debug: get-debug(ctx, debug),
    )

    // if edge appears in a flexigrid, interpret coordinates in uv system by default
    if fletcher-ctx.pass == "final" {
      edge-data.vertices = edge-data.vertices.map(utils.interpret-as-uv)
    }

    // resolve auto vertices to prev/next node
    let (first, .., last) = edge-data.vertices
    if fletcher-ctx.pass == "final" {
      let i = fletcher-ctx.current.node
      if first == auto and i > 0 {
        first = (fletcher-ctx.nodes.at(i - 1).pos)
      }
      if last == auto and i < fletcher-ctx.nodes.len() {
        last = (fletcher-ctx.nodes.at(i).pos)
      }
    }
    
    // give reasonable defaults rather than panic
    if first == auto { first = () }
    if last == auto { last = (rel: (1, 0)) }
    edge-data.vertices.first() = first
    edge-data.vertices.last() = last

    // discard ctx because we do not want to update ctx.prev.pt
    // edge vertices should never affect nodes with relative positions
    let (_, first, ..mid-vertices, last) = cetz.coordinate.resolve(ctx, ..edge-data.vertices)
    edge-data.vertices = (first, ..mid-vertices, last)

    // find nodes to snap to
    let snapping-nodes = edge-data.snap-to.zip((first, last))
      .map(((snap-to, position)) => {
        find-snapping-node(fletcher-ctx.nodes, snap-to, position)
      })

    // get anchors for edges snapping to node
    // this is where we can apply "defocus" adjustments (TODO)
    // and find the best part of an enclose node to snap to
    (first, last) = snapping-nodes.zip((first, last))
      .map(((node, vertex)) => {
        if node == none { return vertex }
        get-snapping-node-anchor(node, vertex)
      })
    edge-data.vertices = (first, ..mid-vertices, last)
    

    if "current" in fletcher-ctx {
      ctx.shared-state.fletcher.current.edge += 1
    }
    if fletcher-ctx.pass != "final" {
      ctx.shared-state.fletcher.edges.push(edge-data)
    }

    cetz.process.many(ctx, {
      draw-edge-with-snapping(edge-data, snapping-nodes)
    })
  },)

}




#let interpret-marks-arg(marks) = {
  if marks == none { (marks: ()) }
  else if type(marks) == array {
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
    args: ("bend",),
    n-vertices: 2,
    draw: (bend, (a, b)) => {
      let perp-dist = if type(bend) == angle {
        let sin-bend = calc.sin(bend)
        if calc.abs(sin-bend) < 1e-3 { return cetz.draw.line(a, b) }
        let half-chord-len = cetz.vector.dist(a, b)/2
        half-chord-len*(1 - calc.cos(bend))/sin-bend
      } else {
        bend
      }
      let midpoint = (a: (a, 50%, b), b: a, number: perp-dist, angle: -90deg)
      cetz.draw.merge-path(cetz.draw.arc-through(a, midpoint, b))
    }
  ),
  bezier-cubic: (
    args: ("from", "to"),
    n-vertices: 2,
    draw: (from, to, (a, b)) => {
      let as-coord(x) = {
        if type(x) == angle { (x, 1) }
        else { x }
      }
      cetz.draw.bezier(a, b, (rel: as-coord(from), to: a), (rel: as-coord(to), to: b))
    }
  ),
  bezier-from: (
    args: ("from",),
    n-vertices: 2,
    draw: (from, (a, b)) => {
      if type(from) == angle { from = (from, 1) }
      cetz.draw.bezier(a, b, (rel: from, to: a))
    }
  ),
  bezier-to: (
    args: ("to",),
    n-vertices: 2,
    draw: (to, (a, b)) => {
      if type(to) == angle { to = (to, 1) }
      cetz.draw.bezier(a, b, (rel: to, to: b))
    }
  ),
  beizer-through: (
    args: ("through",),
    n-vertices: 2,
    draw: (through, (a, b)) => {
      cetz.draw.bezier-through(a, through, b)
    }
  ),
)


#let determine-edge-kind(named, options) = {
  let named-arg-suggestion = none

  for (kind, spec) in EDGE_KINDS {
    let (args, draw) = spec
    if args.all(n => n in named) {
      let draw-args = ()
      for arg in args { draw-args.push(named.remove(arg)) }

      if options.draw != auto {
        utils.error({
          "edge option `draw` must be `auto` when used with "
          args.map(repr).join(", ")
        })
      }
      
      options.draw = draw.with(..draw-args)

      if "n-vertices" in spec {
        if options.vertices.len() != spec.n-vertices {
          utils.error({
            kind
            " edges (with "
            args.map(repr).join(", ")
            " arguments) require exactly "
            repr(spec.n-vertices)
            " vertices; got "
            repr(options.vertices)
          })
        }
      }
      
      break

    } else if args.any(n => n in named) {
      named-arg-suggestion = (kind: kind, args: args)
    }
  }


  // any left over named arguments are unrecognised
  if named.len() > 0 {
    let hint = if named-arg-suggestion != none {
      " For "
      named-arg-suggestion.kind
      " edges, also specify "
      named-arg-suggestion.args
        .filter(n => n not in named)
        .map(repr).join(", ", last: " and ")
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
  let default-spec = (body: none, pos: 50%, side: auto, sep: 3pt)

  let label-args = named.keys().filter(arg => arg.starts-with("label-"))
  for arg in label-args {
    let suffix = arg.trim("label-", at: start)
    if suffix in default-spec {
      default-spec.at(suffix) = named.remove(arg)
    } else {
      let possible-options = default-spec.keys()
        .map(o => "label-" + o)
      utils.error("invalid option #0. Try #..1", repr(arg), possible-options)
    }
  }

  
  let as-label-spec(x) = {
    if x == none {
      return none
    } else if type(x) == dictionary {
      let spec = default-spec
      for (k, v) in x {
        if k in spec { spec.at(k) = v }
        else {
          utils.error("invalid label property #0. Try: #..1", repr(k), spec.keys())
        }
      }
      return spec
    } else if type(x) == content {
      return as-label-spec((body: x))
    } else {
      utils.error("invalid label #0.", repr(x))
    }
  }


  let spec = utils.one-or-array(options.label).map(as-label-spec).filter(l => l != none)
  

  return (named, spec)

}

/// Draw a path with arrow marks, labels, and automatic snapping to nodes.
#let edge(
  /// An edge's positional arguments may specify:
  /// - the edge's @edge.vertices;
  /// - the content of an edge @edge.label;
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
  /// Labels to draw along the edge.
  /// 
  /// ```typc
  /// edge(.., [Hello], label-pos: 50%) // label as positional argument
  /// edge(.., label: [Hello], label-pos: 50%) // label options
  /// edge(.., label: (body: [hello], pos: 50%, ..)) // label dictionary
  /// edge(.., label: ([First label], // array of labels
  ///                  (body: [Second label], pos: 25%)))
  /// ```
  /// 
  /// The label option may be:
  /// - `content` for the label's body
  /// - a `dictionary` of label options:
  ///   - `body`: content to draw
  ///   - `pos`: the label's position along the edge path
  ///   - `sep`: padding between the label's body and the path
  ///   - `side`: which side of the edge to place the body
  /// - an `array` of the above, for multiple labels.
  /// 
  /// Each label option (e.g., `pos`) also exists as an option to @edge (e.g., `edge(label-pos: ..)`).
  label: none,
  snap-to: (auto, auto),
  outset: auto,
  name: none,
  stroke: auto,
  dash: auto,
  /// Draw a separate stroke for each extrusion offset to
  /// obtain a multi-stroke effect. Offsets may be numbers
  /// (specifying multiples of the stroke's thickness) or lengths.
  ///
  /// #frame(diagram({
  ///   (
  ///     (0,),
  ///     (-1.5,+1.5),
  ///     (-2,0,+2),
  ///     (-.5em,),
  ///     (0, 5pt,),
  ///   ).enumerate().map(((i, e)) => {
  ///     edge(
  ///       (2*i, 0), (2*i + 1, 0), [#e], "|->",
  ///       extrude: e, stroke: 1pt, label-sep: 1em)
  ///   }).join()
  /// }))
  ///
  /// Notice how the strokes terminate on the marks properly.
  /// This is defined by the `cap-offset` option of the marks.
  /// TODO
  /// -> number | length | array
  extrude: auto,
  draw: auto,
  debug: auto,
) = {

  let options = (
    vertices: vertices,
    marks: marks,
    label: label,
    snap-to: snap-to,
    outset: outset,
    name: name,
    stroke: stroke,
    dash: dash,
    extrude: extrude,
    draw: draw,
  )

  options += parsing.interpret-edge-positional-args(args.pos(), options)
  options += interpret-marks-arg(options.marks)

  let stroke = utils.stroke-to-dict(options.stroke)
  if options.at("dash", default: auto) != auto {
    stroke.dash = options.dash
  }

  let named = args.named()
  let (named, labels) = interpret-label-args(named, options)
  options += determine-edge-kind(named, options)

  _edge(
    options.vertices,
    style: (
      stroke: stroke,
      outset: utils.as-pair(options.outset),
      marks: options.marks,
      extrude: options.extrude,
    ),
    labels: labels,
    snap-to: options.snap-to,
    name: if name != none { str(options.name) },
    draw: options.draw,
    debug: debug,
  )

}

