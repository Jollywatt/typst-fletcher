#import "deps.typ": cetz
#import "marks.typ" as _marks

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





#let edge(
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
    
    let path = draw(src-snapped, tgt-snapped)
    path
    _marks.draw-marks-on-path(ctx, path, marks)
  })



  if debug >= 1 {
    cetz.draw.group({
      cetz.draw.set-style(stroke: green.transparentize(60%))
      test-draw
    })
  }
}