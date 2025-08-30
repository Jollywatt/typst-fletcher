2#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "paths.typ"
#import "nodes.typ" as Nodes: get-node-origin
#import "debug.typ": debug-level, debug-draw, get-debug
#import "flexigrid.typ"

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

  let b = cetz.util.revert-transform(ctx.transform, reference-point)
  let all-anchors = anchor-names
    .map(get-anchors)
    .sorted(key: a => s*cetz.vector.dist(a, b))

  let best = all-anchors.at(-1, default: b)

  return cetz.util.apply-transform(ctx.transform, best)
}


/// -> (node, node)
#let find-edge-snapping-nodes(edge, nodes) = {
  let (src, .., tgt) = edge.vertices
  edge.snap-to
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
  Nodes.draw-node-at(node, node.pos, debug: false)
}


/// Draw an edge, snapping each end to given CeTZ objects.
#let draw-edge-with-intersection-snapping(
  ctx,
  edge,
  /// Shapes to snap the start and end of the edge to, respectively. -> (cetz, cetz)
  snap-to: (none, none),
  debug: false,
) = {

  let test-path = (edge.draw)(edge.vertices)
  let src-test-path = paths.draw-only-first-path-segment(test-path)
  let tgt-test-path = paths.draw-only-last-path-segment(test-path)

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

    debug-draw(debug, "edge.snap", {
      cetz.draw.circle(src-snapped, radius: 0.5pt, fill: green, stroke: none)
      cetz.draw.circle(tgt-snapped, radius: 0.5pt, fill: red, stroke: none)
      cetz.draw.group({
        cetz.draw.set-style(stroke: (thickness: 0.5pt, paint: purple.transparentize(50%)))
        src-test-path
        tgt-test-path
      })
    })
  })


}

/// Draw an edge, snapping each end to given fletcher nodes.
#let draw-edge-with-snapping(edge, snapping-nodes, debug: false) = {

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

    draw-edge-with-intersection-snapping(
      ctx,
      edge,
      snap-to: snapping-outlines,
      debug: debug,
    )
  })
}


#let _edge(
  vertices,
  style: (:),
  snap-to: (auto, auto),
  name: none,
  draw: auto,
  debug: auto,
) = {

  if draw == auto {
    draw = vertices => cetz.draw.line(..vertices)
  }

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
      debug: debug,
    )

    // resolve auto vertices to prev/next node

    let (first, .., last) = edge-data.vertices

    if fletcher-ctx.pass == "final" {
      let i = fletcher-ctx.current.node

      // this is currently a bit inelegant:
      // in the final pass, we convert all edge vertices from uv -> xy after resolving all coords
      // this means we need node snapping coords to by in uv system
      // but get-node-origin returns xy system, so we need to invert to get uv

      if first == auto and i > 0 {
        first = get-node-origin(fletcher-ctx.nodes.at(i - 1), fletcher-ctx.flexigrid)
        first = utils.xy-to-uv(fletcher-ctx.flexigrid, first)
      }
      if last == auto and i < fletcher-ctx.nodes.len() {
        last = get-node-origin(fletcher-ctx.nodes.at(i), fletcher-ctx.flexigrid)
        last = utils.xy-to-uv(fletcher-ctx.flexigrid, last)
      }
    }
    
    // give reasonable defaults rather than panic
    if first == auto { first = () }
    if last == auto { last = (rel: (1, 0)) }

    edge-data.vertices.first() = first
    edge-data.vertices.last() = last
    
    // normalize anchor labels to strings
    edge-data.vertices = edge-data.vertices.map(coord => {
      if type(coord) == label { str(coord) }
      else { coord }
    })

    let (ctx, ..verts) = cetz.coordinate.resolve(ctx, ..edge-data.vertices)
    edge-data.vertices = verts

    let snapping-nodes = find-edge-snapping-nodes(edge-data, fletcher-ctx.nodes)

    // apply flexigrid coordinates
    if fletcher-ctx.pass == "final" {
      edge-data.vertices = edge-data.vertices.map(vertex => {
        utils.uv-to-xy(fletcher-ctx.flexigrid, vertex)
      })

      snapping-nodes = snapping-nodes.map(node => {
        if node == none { return }
        node.pos = get-node-origin(node, fletcher-ctx.flexigrid)
        node
      }) 
    }

    if debug == auto {
      edge-data.debug = get-debug(ctx, edge-data.debug)
    }

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
    extrude: extrude,
    stroke: stroke,
    draw: draw,
  )
  
  options += parsing.interpret-edge-args(args, options)
  options += interpret-marks-arg(options.marks)

  let stroke = (dash: options.at("dash", default: auto)) + utils.stroke-to-dict(options.stroke)

  
  _edge(
    options.vertices,
    style: (
      stroke: stroke,
      outset: utils.as-pair(options.outset),
      marks: options.marks,
      extrude: options.extrude,
    ),
    snap-to: options.snap-to,
    name: name,
    draw: options.draw,
    debug: debug,
  )

}
