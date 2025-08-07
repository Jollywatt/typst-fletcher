#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as Marks
#import "parsing.typ"
#import "nodes.typ" as Nodes
#import "debug.typ": debug-level

#let BASE_EDGE_STYLE = (
  marks: (),
  stroke: 1pt,
)

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

#let draw-edge(edge) = {
  cetz.draw.get-ctx(ctx => {

    let style = cetz.styles.resolve(
      ctx.style,
      base: BASE_EDGE_STYLE,
      merge: (edge: edge.style),
      root: "edge",
    ).edge

    let test-path = cetz.draw.line(..edge.path)

    Marks.draw-with-marks-and-shrinking(ctx, test-path, style.marks, stroke: style.stroke)
  })
}


#let draw-edge-with-snapping(
  edge,
  source,
  target,
  snap-to: (none, none),
  draw: none,
  marks: (),
  debug: false,
) = {

  let marks = Marks.interpret-marks(marks)

  let test-path = cetz.draw.line(..edge.path)
  cetz.draw.hide({
    cetz.draw.intersections("inter-src", snap-to.at(0) + test-path)
    cetz.draw.intersections("inter-tgt", snap-to.at(1) + test-path)
  })

  cetz.draw.get-ctx(ctx => {
    let src-snapped = find-farthest-anchor(ctx, "inter-src", source)
    let tgt-snapped = find-farthest-anchor(ctx, "inter-tgt", target)
    let (_, ..mid-vertices, _) = edge.path
    let obj = draw-edge(edge + (path: (src-snapped, ..mid-vertices, tgt-snapped)))
    Marks.draw-with-marks(ctx, obj, marks)
  })


  if debug-level(debug, "edge") {
    cetz.draw.group({
      cetz.draw.set-style(stroke: (paint: green.transparentize(60%)))
      test-path
    })
  }
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




#let find-snapping-nodes(key, nodes) = {
  if key == none { return none }
  let (u0, v0) = key
  let node = nodes.sorted(key: node => {
    let (u, v) = node.pos
    calc.abs(u - u0) + calc.abs(v - v0)
  }).first()

  Nodes.draw-node-at(node, node.origin, debug: false)

}

#let draw-edge-in-flexigrid(edge, grid, nodes, debug: false) = {
  let vertices-xy = edge.vertices.map(utils.interp-grid-point.with(grid))
  let (src, ..mid-vertices, tgt) = vertices-xy

  let (src-snap-to, tgt-snap-to) = edge.snap-to
  if src-snap-to == auto { src-snap-to = src }
  if tgt-snap-to == auto { tgt-snap-to = tgt }
  let src-snap-nodes = find-snapping-nodes(src-snap-to, nodes)
  let tgt-snap-nodes = find-snapping-nodes(tgt-snap-to, nodes)

  draw-edge-with-snapping(
    edge + (path: vertices-xy),
    src,
    tgt,
    snap-to: (src-snap-nodes, tgt-snap-nodes),
    debug: utils.map-auto(edge.debug, debug),
  )
}


#let _edge(
  vertices,
  style: (:),
  snap-to: (auto, auto),
  debug: auto,
) = {


  let edge-data = (
    class: "edge",
    vertices: vertices,
    style: style,
    snap-to: snap-to,
    debug: debug,
  )
  
  (ctx => {

    let (obj,) = draw-edge(edge-data + (
      path: edge-data.vertices
    ))

    obj(ctx) + (fletcher: edge-data)

  },)

}



#let edge(
  ..args,
  marks: (),
  snap-to: (auto, auto),
  debug: auto,
) = {

  let options = (
    marks: marks,
    snap-to: snap-to,
  )
  
  options += parsing.interpret-edge-args(args, options)
  options += interpret-marks-arg(options.marks)
  
  _edge(
    options.vertices,
    style: (
      marks: options.marks,
    ),
    snap-to: options.snap-to
  )

}
