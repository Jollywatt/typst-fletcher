= FlexiCeTZ

#import "@preview/cetz:0.4.1"

#import "utils.typ": *

#import "flexigrid.typ": *
#import "shapes.typ"



#let node(
  pos,
  content,
  name: none,
  align: center + horizon,
  shape: shapes.rect,
) = {
  ((
    class: "node",
    pos: pos,
    content: content,
    name: name,
    align: align,
    shape: shape,
  ),)
}

#v(1cm)

#let fig = cetz.canvas({
  import cetz.draw
  draw.circle((0, 0), radius: 30mm, name: "phil", stroke: yellow.transparentize(70%))

  flexigrid(
    {
      node((0, 0), $U$, name: "A")
      node((1, 1), $ a + b/c $, name: "B")
      node((2, 0), $ frak(B)/oo $)
      node((1, 0), circle(fill: teal), align: top, shape: shapes.circle, name: "C")
      cetz.draw.circle("C.30deg", radius: 3pt, fill: blue)
    },
    gutter: 10pt,
    debug: 1,
    origin: "phil.south",
    name: "f",
  )
  draw.line("f.A.north-east", "f.B.west")
})

#text(3em, box(fill: luma(96%), fig))

#v(3cm)
== Edges
#v(3cm)

#let dotmark = cetz.draw.circle.with(radius: 1.5pt, stroke: none)

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

#let edge((src, tgt), snap-to: (auto, auto), draw: none, debug: 0) = {

  let test-draw = (draw)(src, tgt)
  cetz.draw.hide(cetz.draw.intersections("inter-src", snap-to.at(0) + test-draw))
  cetz.draw.hide(cetz.draw.intersections("inter-tgt", snap-to.at(1) + test-draw))

  cetz.draw.get-ctx(ctx => {

    let src-snapped = find-farthest-anchor(ctx, "inter-src", src)
    let tgt-snapped = find-farthest-anchor(ctx, "inter-tgt", tgt)
    
    // anchor-names.map(a => dotmark((name: "inter-tgt", anchor: a), fill: green)).join()
    // dotmark(best, stroke: green, radius: 3pt)
    
    draw(src-snapped, tgt-snapped)
  })

  if debug >= 1 {
    cetz.draw.group({
      cetz.draw.set-style(stroke: green.transparentize(60%))
      test-draw
    })
  }


}


#cetz.canvas({
  import cetz.draw

  draw.rotate(20deg)
  draw.scale(x: -1)
  let a = draw.circle((0,1))
  let b = draw.rect((5,0), (2,1))
  let c = draw.rect((4,4), (3,2))
  a + b + c


  edge(((0,1), (5,3)), snap-to: (a, c), draw: (a, b) => draw.arc-through(a, (2,3), b), debug: 1)

  flexigrid(
    {
      node((0,0), none)
      node((5,5), none)
    },
    debug: 1,
    gutter: 1cm,
  )
})