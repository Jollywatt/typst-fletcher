#import "deps.typ": cetz
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

#let edge(
  ..args
) = {
  let args = parsing.interpret-edge-args(args, (:))

  ((
    class: "edge",
    ..args
  ),)
}

#let draw-edge(edge, objects) = {
  cetz.draw.line(..edge.vertices)
}