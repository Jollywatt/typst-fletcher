2#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "paths.typ"
#import "nodes.typ" as Nodes
#import "debug.typ": debug-level, debug-draw

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

  Marks.draw-with-marks-and-extrusion(ctx, path, style.marks, stroke: style.stroke, extrude: style.extrude)

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

#let find-farthest-anchor(ctx, name, reference-point) = {

  let get-anchors = ctx.nodes.at(name).anchors
  let anchor-names = (get-anchors)(())

  let b = cetz.util.revert-transform(ctx.transform, reference-point)
  let all-anchors = anchor-names
    .map(get-anchors)
    .sorted(key: a => cetz.vector.dist(a, b))

  let best = all-anchors.at(-1, default: b)

  return cetz.util.apply-transform(ctx.transform, best)
}

/// Find a node by its approximate position.
/// Returns `none` if no nodes are nearby.
/// 
/// -> node | none
#let find-closest-node(nodes, key) = {
  if key == none { return none }

  if type(key) == array {
    key = (system: "uv", coord: key)
  }

  if type(key) == dictionary {
    assert("system" in key and "coord" in key)

    let dist
    let max-dist

    if key.system == "uv" {
      // find node closest to given coordinate
      dist(node) = cetz.vector.sub(key.coord, node.pos).map(calc.abs).sum()
      let node = nodes.sorted(key: dist).first()
      if dist(node) > 1 { return }
      return node
    } else if key.system == "xy" {
      let dist(node) = cetz.vector.len(cetz.vector.sub(key.coord, node.origin))
      let node = nodes.sorted(key: dist).first()
      max-dist = cetz.vector.len(node.size)
      if dist(node) > max-dist { return }
      return node
    }
  }

  utils.error("invalid `snap-to` key: #0", key)
}

/// -> (node, node)
#let find-edge-snapping-nodes(edge, nodes) = {

  edge.snap-to.zip((edge.vertices.first(), edge.vertices.last()))
    .map(((snap-to, vertex)) => {
      if type(snap-to) == str { return snap-to } // snap to by name
      if snap-to == auto { snap-to = (system: "xy", coord: vertex) }
      find-closest-node(nodes, snap-to)
    })

}


#let draw-node-snapping-outline(node, outset) = {
  let node = node
  if outset == auto { outset = node.style.outset }
  node.style.extrude = (outset,)
  node.name = none
  node.body = none
  Nodes.draw-node-at(node, node.origin, debug: false)
}


/// Draw an edge, snapping each end to given CeTZ objects.
#let draw-edge-with-intersection-snapping(
  edge,
  /// Shapes to snap the start and end of the edge to, respectively. -> (cetz, cetz)
  snap-to: (none, none),
  debug: false,
) = {

  let test-path = (edge.draw)(edge.vertices)

  cetz.draw.hide({
    cetz.draw.intersections("__src__", snap-to.at(0) + test-path)
    cetz.draw.intersections("__tgt__", snap-to.at(1) + test-path)
  })

  cetz.draw.get-ctx(ctx => {
    let src-snapped = find-farthest-anchor(ctx, "__src__", edge.vertices.first())
    let tgt-snapped = find-farthest-anchor(ctx, "__tgt__", edge.vertices.last())

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
        test-path
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

  let edge-data = (
    class: "edge",
    vertices: vertices,
    style: style,
    snap-to: snap-to,
    name: name,
    draw: draw,
    debug: debug,
  )
  
  (ctx => {

    let objs = draw-edge(ctx, edge-data)

    let (ctx, drawables) = cetz.process.many(ctx, objs)

    return (
      ctx: ctx,
      drawables: drawables,
      fletcher: edge-data,
    )

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
    marks: marks,
    snap-to: snap-to,
    outset: outset,
    extrude: extrude,
    stroke: stroke,
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
    draw: draw,
    debug: debug,
  )

}
