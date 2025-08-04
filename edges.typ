#import "deps.typ": cetz
#import "utils.typ"
#import "marks.typ" as _marks
#import "parsing.typ"

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
  snap-to: (auto, auto),
  draw: none,
  debug: 0,
  marks: (),
) = {

  let marks = _marks.interpret-marks(marks)

  let test-draw = (draw)(source, target)
  cetz.draw.hide(cetz.draw.intersections("inter-src", snap-to.at(0) + test-draw))
  cetz.draw.hide(cetz.draw.intersections("inter-tgt", snap-to.at(1) + test-draw))

  cetz.draw.get-ctx(ctx => {

    let src-snapped = find-farthest-anchor(ctx, "inter-src", source)
    let tgt-snapped = find-farthest-anchor(ctx, "inter-tgt", target)
    
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

#let edge(
  ..args,
  marks: ()
) = {

  let options = (
    marks: marks,
  )
  
  options += parsing.interpret-edge-args(args, options)
  options += interpret-marks-arg(options.marks)
  

  ((
    class: "edge",
    ..options
  ),)
}

#let resolve-edge(edge, uv-to-xy, objects) = {
  edge.draw = cetz.draw.line(..edge.vertices.map(uv-to-xy))
  edge
}

#let draw-edge(edge) = {
  cetz.draw.get-ctx(ctx => {
    _marks.draw-with-marks(ctx, edge.draw, edge.marks)
  })
}