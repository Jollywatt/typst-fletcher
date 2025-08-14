#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
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

  let base-path = cetz.draw.line(..edge.path, name: edge.name)

  Marks.draw-with-marks-and-shrinking(ctx, base-path, style.marks, stroke: style.stroke)
}

#let find-farthest-anchor(ctx, name, reference-point) = {

  let get-anchors = ctx.nodes.at(name).anchors
  let anchor-names = (get-anchors)(())

  let inv-transform = cetz.matrix.inverse(ctx.transform)
  let all-anchors = anchor-names
    .map(get-anchors)
    .map(a => cetz.matrix.mul4x4-vec3(inv-transform, a))
    .sorted(key: a => cetz.vector.dist(a, reference-point))

  let best = all-anchors.at(-1, default: reference-point)

  return best
}


/// -> (node, node)
#let find-edge-snapping-nodes(edge, nodes) = {
  let nodes-from-key(key) = {
    if key == none { return none } // snapping disabled
    else if type(key) == str { return key } // snap to object by name
    else if type(key) == array { // snap to node by location
      let (x0, y0) = key
      // find closest node
      let node = nodes.sorted(key: node => {
        let (x, y) = node.origin
        calc.abs(x - x0) + calc.abs(y - y0)
      }).first()
      return node
    } else {
      utils.error("invalid `snap-to` key: #0", key)
    }
  }

  let (src-snap-to, tgt-snap-to) = edge.snap-to
  if src-snap-to == auto { src-snap-to = edge.vertices.first() }
  if tgt-snap-to == auto { tgt-snap-to = edge.vertices.last() }


  let src-nodes = nodes-from-key(src-snap-to)
  let tgt-nodes = nodes-from-key(tgt-snap-to)
  return (src-nodes, tgt-nodes)
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

  let test-path = cetz.draw.line(..edge.vertices)
  cetz.draw.hide({
    cetz.draw.intersections("__src__", snap-to.at(0) + test-path)
    cetz.draw.intersections("__tgt__", snap-to.at(1) + test-path)
  })

  cetz.draw.get-ctx(ctx => {
    let src-snapped = find-farthest-anchor(ctx, "__src__", edge.vertices.first())
    let tgt-snapped = find-farthest-anchor(ctx, "__tgt__", edge.vertices.last())

    if (src-snapped == tgt-snapped) {
      utils.error("edge snapping resulted in same source and target points")
    }

    let (_, ..mid-vertices, _) = edge.vertices
    draw-edge(ctx, edge + (path: (src-snapped, ..mid-vertices, tgt-snapped)))

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

    let (src, ..mid-vertices, tgt) = edge.vertices
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
  debug: auto,
) = {

  
  // if snap-to.first() == auto { snap-to.first() = vertices.first() }
  // if snap-to.last() == auto { snap-to.last() = vertices.last() }

  let edge-data = (
    class: "edge",
    vertices: vertices,
    style: style,
    snap-to: snap-to,
    name: name,
    debug: debug,
  )
  
  (ctx => {

    let objs = draw-edge(ctx, edge-data + (
      path: edge-data.vertices
    ))

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
    debug: debug,
  )

}
