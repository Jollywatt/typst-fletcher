#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "paths.typ"
#import "nodes.typ" as Nodes
#import "debug.typ": debug-level, debug-draw, get-debug

#let DEFAULT_EDGE_STYLE = (
  marks: (),
  stroke: (thickness: 0.048em, cap: "round"),
  extrude: (0,),
)

#let draw-edge(ctx, edge) = {
  let style = cetz.styles.resolve(
    ctx.style,
    base: DEFAULT_EDGE_STYLE,
    merge: (edge: edge.style),
    root: "edge",
  ).edge

  let path = (edge.draw)(edge.vertices)
  assert(path.len() == 1, message: "edge.draw should return single cetz element")

  Marks.draw-with-marks-and-extrusion(ctx, path, style.marks, stroke: style.stroke, extrude: style.extrude, debug: edge.debug)

  // create proxy named cetz object which draws nothing but handles anchors
  (ctx => {
    let a =  path.first()(ctx)
    if "anchors" not in a {panic(a.keys())}
    let (anchors, drawables) = path.first()(ctx)
    return (
      ctx: ctx,
      name: edge.name,
      anchors: anchors,
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


/// -> (node, node)
#let find-edge-snapping-nodes(snap-to, (src, tgt), nodes) = {
  snap-to
    .zip((src, tgt))
    .map(((snap-to, vertex)) => {
      if type(snap-to) == str { // snap to by name
        let node = nodes.find(n => n.name == snap-to)
        if node == none { utils.error("couldn't find name #0", snap-to) }
        return node
      }
      if snap-to == auto { snap-to = vertex }
      let dist(node) = cetz.vector.dist(node.pos, vertex)
      
      return nodes
        .filter(n => dist(n) <= cetz.vector.len(n.size)/2)
        .sorted(key: dist)
        .at(0, default: none)
    })
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

    debug-draw(edge.debug, "edge.snap", {
      cetz.draw.group({
        cetz.draw.set-style(stroke: (thickness: 0.5pt, paint: purple.transparentize(50%)))
        src-test-path
        tgt-test-path
      })
      cetz.draw.circle(src-snapped, radius: 1pt, fill: green, stroke: none)
      cetz.draw.circle(tgt-snapped, radius: 1pt, fill: red, stroke: none)
    })
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

    let style = cetz.styles.resolve(
      ctx.style,
      base: DEFAULT_EDGE_STYLE,
      merge: (edge: edge.style),
    ).edge

    let snapping-outlines = snapping-nodes
      .zip(edge.style.outset)
      .map(((key, outset)) => {
        if key == none { return }
        if type(key) == str {
          if key not in ctx.nodes { utils.error("couldn't find name #0", key) }
          let drawables = ctx.nodes.at(key).drawables
          return (ctx => (ctx: ctx, drawables: drawables),)
        } else if utils.is-node(key) {
          let node = key
          node.style = cetz.styles.resolve(
            ctx.style,
            base: Nodes.DEFAULT_NODE_STYLE,
            merge: (node: node.style),
            root: "node",
          ).node
          draw-node-snapping-outline(node, outset)
        }
      })

    if debug-level(edge.debug, "edge.snap") {
      snapping-outlines.join()
    }

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
      style: style,
      snap-to: snap-to,
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
    let (_, ..verts) = cetz.coordinate.resolve(ctx, ..edge-data.vertices)
    edge-data.vertices = verts


    let snapping-nodes = find-edge-snapping-nodes(
      edge-data.snap-to,
      (verts.first(), verts.last()),
      fletcher-ctx.nodes,
    )

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


#let determine-edge-kind(args, options) = {

  let named = args.named()
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
		utils.error("Unknown edge arguments #..0." + hint, args.named().keys())
	}

  if options.draw == auto {
    options.draw = vertices => cetz.draw.line(..vertices)
  }

  return (draw: options.draw)
  
}



#let edge(
  ..args,
  vertices: (),
  marks: (),
  snap-to: (auto, auto),
  outset: auto,
  name: none,
  stroke: auto,
  extrude: auto,
  draw: auto,
  debug: auto,
) = {

  let options = (
    vertices: vertices,
    marks: marks,
    snap-to: snap-to,
    outset: outset,
    name: name,
    stroke: stroke,
    extrude: extrude,
    draw: draw,
  )
  
  options += parsing.interpret-edge-positional-args(args.pos(), options)
  options += interpret-marks-arg(options.marks)

  let stroke = { // fold strokes
    (dash: options.at("dash", default: auto))
    utils.stroke-to-dict(options.stroke)
  }

  options += determine-edge-kind(args, options)

  _edge(
    options.vertices,
    style: (
      stroke: stroke,
      outset: utils.as-pair(options.outset),
      marks: options.marks,
      extrude: options.extrude,
    ),
    snap-to: options.snap-to,
    name: if name != none { str(options.name) },
    draw: options.draw,
    debug: debug,
  )

}
