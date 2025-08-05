#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as _marks
#import "parsing.typ"
#import "nodes.typ" as Nodes

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



#let draw-edge-with-snapping(
  source,
  target,
  snap-to: (none, none),
  draw: none,
  marks: (),
  debug: false,
) = {

  let marks = _marks.interpret-marks(marks)

  let test-draw = (draw)(source, target)
  cetz.draw.hide(cetz.draw.intersections("inter-src", snap-to.at(0) + test-draw))
  cetz.draw.hide(cetz.draw.intersections("inter-tgt", snap-to.at(1) + test-draw))

  cetz.draw.get-ctx(ctx => {

    let src-snapped = find-farthest-anchor(ctx, "inter-src", source)
    let tgt-snapped = find-farthest-anchor(ctx, "inter-tgt", target)
    snap-to.at(0)
    let obj = draw(src-snapped, tgt-snapped)
    _marks.draw-with-marks(ctx, obj, marks)
  })


  // if debug >= 1 {
  //   cetz.draw.group({
  //     cetz.draw.set-style(stroke: (paint: green.transparentize(60%)))
  //     test-draw
  //   })
  // }
}

#let interpret-marks-arg(marks) = {
  if marks == none { (marks: ()) }
  else if type(marks) == array {
    (marks: _marks.interpret-marks(marks))
  } else if type(marks) in (str, symbol) {
    let (marks, options) = parsing.parse-mark-shorthand(marks)
    (marks: _marks.interpret-marks(marks), ..options)
  } else {
    utils.error("could not interpret marks argument: #0", marks)
  }
}

#let draw-edge(edge) = {
  cetz.draw.get-ctx(ctx => {
    _marks.draw-with-marks-and-shrinking(ctx, edge.draw, edge.marks)
  })
}


#let edge(
  ..args,
  marks: (),
  snap-to: (auto, auto)
) = {

  let options = (
    marks: marks,
    snap-to: snap-to,
  )
  
  options += parsing.interpret-edge-args(args, options)
  options += interpret-marks-arg(options.marks)

  let edge-data = (
    class: "edge",
    ..options
  )

  edge-data.draw = cetz.draw.line(..edge-data.vertices)
  
  (ctx => {

    let (obj,) = draw-edge(edge-data)

    obj(ctx) + (fletcher: edge-data)

  },)

}


#let find-snapping-nodes(key, nodes) = {
  if key == none { return none }
  let (u0, v0) = key
  let node = nodes.sorted(key: node => {
    let (u, v) = node.pos
    calc.abs(u - u0) + calc.abs(v - v0)
  }).first()

  Nodes.draw-node-at(node, node.origin)

}

#let draw-edge-in-flexigrid(edge, grid, nodes) = {
  let vertices-xy = edge.vertices.map(utils.interp-grid-point.with(grid))
  let (src, ..mid-vertices, tgt) = vertices-xy
  edge.draw = cetz.draw.line(..vertices-xy)

  let (src-snap-to, tgt-snap-to) = edge.snap-to
  if src-snap-to == auto { src-snap-to = src }
  if tgt-snap-to == auto { tgt-snap-to = tgt }
  let src-snap-nodes = find-snapping-nodes(src-snap-to, nodes)
  let tgt-snap-nodes = find-snapping-nodes(tgt-snap-to, nodes)

  draw-edge-with-snapping(
    src,
    tgt,
    draw: (src, tgt) => {
      let edge = edge
      edge.draw = cetz.draw.line(src, ..mid-vertices, tgt)
      draw-edge(edge)
    },
    snap-to: (src-snap-nodes, tgt-snap-nodes),
  )
}