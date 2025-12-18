#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "paths.typ"
#import "intersection.typ": trim-drawable
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
        utils.error("label options `anchor: #0` and `side: #1` cannot be used together; one must be `auto`", repr(label.anchor), repr(label.side))
      }
      // anchor is set explicitly; don't deduce anchor from side
      label.side = none
    }

    // 1. resolve label.angle to angle
    if type(label.angle) == alignment {
      label.angle = tangent-angle - (
        right: 0deg,
        top: 90deg,
        left: 180deg,
        bottom: 270deg,
      ).at(repr(label.angle))
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
        label.side = accel.at(0)*vel.at(1) - accel.at(1)*vel.at(0) > 0
        // formula comes from sign of z-coord of cross product
      } else {
        // ...if edge is straight, label is generally north of it
        label.side = top
      }
    }
    
    if type(label.side) == alignment {
      let v = (0,0)
      if label.side.x == right  { v.first() = +1 }
      if label.side.x == left   { v.first() = -1 }
      if label.side.y == top    { v.last()  = +1 }
      if label.side.y == bottom { v.last()  = -1 }
      if v == (0,0) {
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

#let edge-effects(
  ctx,
  obj,
  stroke: 1pt,
  labels: (),
  marks: (),
  snap-to: (none, none),
  extrude: (0,),
  debug: false,
) = {

  let (ctx, drawables, bounds) = cetz.process.many(ctx, obj)
  let drawable = drawables.first()
  
  if snap-to.first() != none {
    drawable = trim-drawable(drawable, snap-to.first(), from-end: true)
  }
  if snap-to.last() != none {
    drawable = trim-drawable(drawable, snap-to.last(), from-end: false)
  }

  let (shorten-start, shorten-end, marks) = Marks.draw-marks-on-path(
		ctx,
		drawable.segments,
		marks,
		stroke: stroke,
		extrude: extrude,
		debug: debug,
	)

  let path = drawable.segments

  paths._path-effect(
    ctx,
    (drawable,),
    shorten-start: shorten-start,
    shorten-end: shorten-end,
    stroke: stroke,
    fill: none,
    extrude: extrude,
  )

  marks

  draw-labels-on-path(ctx, path, labels, debug: debug)
}

/// todo: replace this with `draw-edge(ctx, path)`
/// should be usable by itself to apply effects to cetz
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

  let group = {
    paths.path-effect(
      objs,
      shorten-start: shorten-start,
      shorten-end: shorten-end,
      stroke: edge.style.stroke,
      fill: none,
      extrude: edge.style.extrude,
    )
    marks
    draw-labels-on-path(ctx, path, edge.labels, debug: edge.debug)
  }
  if edge.layer != 0 { group = cetz.draw.on-layer(edge.layer, group) }
  group

  if debug-level(edge.debug, "edge.snap") {
    debug-group({
      cetz.draw.set-style(stroke: (thickness: 0.5pt, paint: purple.transparentize(50%)), fill: none)
      (edge.draw)(edge.pre-snapping-vertices)
      let t = utils.get-thickness(edge.style.stroke)
      // cetz.draw.circle(src-snapped, radius: t, fill: green.transparentize(50%), stroke: none)
      // cetz.draw.circle(tgt-snapped, radius: t, fill: red.transparentize(50%), stroke: none)
    })
  }


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

#let draw-edge(ctx, edge) = {

  edge-effects(
    ctx,
    (edge.draw)(edge.vertices),
    stroke: edge.style.stroke,
    extrude: edge.style.extrude,
    marks: edge.style.marks,
    labels: edge.labels,
    snap-to: edge.snap-to,
    debug: edge.debug,
  )
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
    // if node == none { utils.error("couldn't find name #0", snap-to) }
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


#let find-snapping-drawables(ctx, nodes, edge) = {
  let node-drawables(node, outset) = {
    let objs = draw-node-snapping-outline(node, outset)
    return cetz.process.many(ctx, objs).drawables
  }

  return (0, -1).map(i => { // first and last index
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
      let node = nodes
        .filter(n => dist(n) <= cetz.vector.len(n.size)/2)
        .sorted(key: dist)
        .at(0, default: none)
      if node != none {
        target-drawables = node-drawables(node, outset)
      }
    }

    return target-drawables
  })

}


#let apply-edge-snapping(ctx, nodes, edge) = {
  let node-drawables(node, outset) = {
    let objs = draw-node-snapping-outline(node, outset)
    return cetz.process.many(ctx, objs).drawables
  }

  for i in (0, -1) { // first and last index
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
      let node = nodes
        .filter(n => dist(n) <= cetz.vector.len(n.size)/2)
        .sorted(key: dist)
        .at(0, default: none)
      if node != none {
        target-drawables = node-drawables(node, outset)
      }
    }

    // find snapping points by intersecting edge path with target
    // if target-drawables != none {
    //   let edge-element = (edge.draw)(edge.vertices)
    //   let edge-drawable = if i == 0 {
    //     paths.drawable-with-only-first-segment(ctx, edge-element)
    //   } else {
    //     paths.drawable-with-only-last-segment(ctx, edge-element)
    //   }
    //   let pos-inv = cetz.util.apply-transform(ctx.transform, pos)
    //   let pts = target-drawables.map(path => {
    //     cetz.intersection.path-path(edge-drawable, path)
    //   }).join() + () // coerce none to array
    //   pts = pts.sorted(key: pt => cetz.vector.dist(pt, pos-inv))
    //   if pts.len() == 0 { continue }
    //   let farthest-point = pts.first()
    //   edge.vertices.at(i) = cetz.util.revert-transform(ctx.transform, farthest-point)
    // }

    if target-drawables != none {
      let edge-element = (edge.draw)(edge.vertices)

      let o = trim-drawable(edge-element.first(), target-drawables)
      panic(o)

    }
  }

  return edge.vertices
}


#let _edge(
  vertices,
  style: (:),
  labels: (),
  snap-to: (auto, auto),
  name: none,
  draw: vertices => none,
  layer: 0,
  debug: auto,
) = {

  cetz.draw.get-ctx(ctx => {
    
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
      layer: layer,
      debug: get-debug(ctx, debug),
    )

    // resolve styles
    let ctx-edge = ctx.style.at("edge", default: (:))
    ctx-edge.stroke = utils.stroke-to-dict(ctx-edge.at("stroke", default: (:)))
    edge-data.style = cetz.styles.resolve(
      ctx-edge,
      base: DEFAULT_EDGE_STYLE,
      merge: edge-data.style,
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
    let (_, first, ..mid-vertices, last) = cetz.coordinate.resolve(ctx, ..edge-data.vertices)
    edge-data.vertices = (first, ..mid-vertices, last)


    edge-data.pre-snapping-vertices = edge-data.vertices
    // edge-data.vertices = apply-edge-snapping(ctx, fletcher-ctx.nodes, edge-data)


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
      let snap-to = find-snapping-drawables(ctx, fletcher-ctx.nodes, edge-data)
      edge-data.snap-to = snap-to
      draw-edge(ctx, edge-data)
    }
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
    } else {
      return as-label-spec((body: x))
    }
  }


  let spec = utils.one-or-array(options.label).map(as-label-spec).filter(l => l != none)
  

  return (named, spec)

}

/// Draw a path with arrow marks, labels, and automatic snapping to nodes.
#let edge(
  /// An edge's positional arguments may specify:
  /// - the edge's @edge.vertices, each given as a CeTZ coordinate;
  /// - the edge's @edge.marks, e.g., `"->"` or `"solid=/=solid"`.
  /// - the body content of an edge @edge.label, e.g., `$f$`;
  /// - some other style flags (#fletcher.edges.parsing.EDGE_FLAGS.keys().map(raw).join[, ]).
  /// 
  /// Vertex coordinates must come first, and are optional:
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
  /// If given as positional arguments, an edge's @edge.marks and @edge.label
  /// are disambiguated based on their types.
  /// For example, the following are equivalent:
  /// ```typc
  /// edge((0,0), (1,0), $f$, "->")
  /// edge((0,0), (1,0), "->", $f$)
  /// edge((0,0), (1,0), $f$, marks: "->")
  /// edge((0,0), (1,0), "->", label: $f$)
  /// edge((0,0), (1,0), label: $f$, marks: "->")
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
  /// Possible label option are:
  /// - `body`: content to draw
  /// - `pos`: the label's position along the edge path
  /// - `sep`: padding between the label's body and the path
  /// - `side`: which side of the edge to place the body
  /// 
  /// Each option has a corresponding edge argument (e.g., `edge(label-pos: ..)`).
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
  /// ```svg
  /// stack(
  ///   dir: ltr,
  ///   spacing: 1cm,
  ///   ..(0%, 25%, 50%, 75%, 100%).map(p => fletcher.diagram(
  ///   gutter: 2cm,
  ///   	edge((0,0), (1,0), [#p], "->", label-pos: p))
  ///   ),
  /// )
  /// ```
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
  /// If `center` or `none`, the label is placed directly over the edge, and the label fill defaults to white.
  /// 
  /// An alignment (e.g., `top`, `left`, `top + left`) means place the label beside the edge to whichever side is nearer that direction.
  /// If given as an alignment, the side may flip depending on the edge's angle.
  /// 
  /// If `true`, the label is placed above the edge assuming it goes left to right;
  /// `false` is the opposite side.
  /// If given as a boolean, the side does not flip depending on the edge's angle.
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
  /// ```svg
  /// stack(
  ///   dir: ltr,
  ///   spacing: 5mm,
  ///   ..(0deg, 90deg, auto, right, top, bottom).map(angle => {
  ///     diagram(edge((0,1), (2,0), "->", [#angle], label-angle: angle))
  ///   }).map(align.with(bottom)),
  /// )
  /// ```
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
  snap-to: (auto, auto),
  outset: auto,
  name: none,
  stroke: auto,
  dash: auto,
  /// Draw a separate stroke for each extrusion offset to
  /// obtain a multi-stroke effect. Offsets may be numbers
  /// (specifying multiples of the stroke's thickness) or lengths.
  ///
  /// ```svg
  /// diagram({
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
  /// })
  /// ```
  ///
  /// Notice how the strokes terminate on the marks properly.
  /// This is defined by the `cap-offset` option of the marks.
  /// TODO
  /// -> number | length | array
  extrude: auto,
  /// Canvas layer to draw edge on.
  /// 
  /// Edges with equal layer are drawn in the order they are inserted.
  /// -> number
  layer: 0,

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
    layer: layer,
    draw: draw,
  )

  options += parsing.interpret-edge-positional-args(args.pos(), options)
  options += interpret-marks-arg(options.marks)

  if options.stroke == none {
    options.stroke = 1pt
    options.extrude = ()
  }

  let stroke = utils.stroke-to-dict(options.stroke)
  if options.at("dash", default: auto) != auto {
    stroke.dash = options.dash
  }

  let named = args.named()
  let (named, labels) = interpret-label-args(named + (
    label-pos: label-pos,
    label-side: label-side,
    label-sep: label-sep,
    label-fill: label-fill,
    label-angle: label-angle,
    label-anchor: label-anchor,
  ), options)
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
    layer: layer,
    debug: debug,
  )

}

