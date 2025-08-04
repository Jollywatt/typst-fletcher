#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

= FlexiCeTZ

This is some text for size.
#diagram(debug: (grid: 8, nodes: 100), {
  node((0,0), [Hello\ World], name: "A")
  node((1,1), [Royal], name: "B")
}, gutter: 5mm)

#cetz.canvas({
  import cetz.draw

  flexigrid({
    node((0,0), [hello])
    // edge((0,0))
    node((2,0), [a])
  }, columns: 1cm, debug: "grid.cells", gutter: 5mm)
})

#let fig = cetz.canvas({
  import cetz.draw
  draw.circle((0, 0), radius: 30mm, name: "phil", stroke: yellow.transparentize(70%))

  flexigrid(
    {
      node((0, 0), $U$, name: "A")
      node((1, 1), $ a + b/c $, name: "B")
      node((2, 0), $ frak(B)/oo $)
      node((1, 0), circle(fill: teal), align: left, shape: shapes.circle, name: "C")
      cetz.draw.circle("C.40deg", radius: 3pt, fill: blue)
      cetz.draw.circle("A.north", radius: 3pt, fill: blue)
    },
    gutter: 10pt,
    debug: 1,
    origin: "phil.south",
    name: "f",
  )
  draw.line("f.A.north-east", "f.B.west")
})

#text(3em, box(fill: luma(96%), fig))

== Edges

#import "@preview/fletcher:0.5.8"

#fletcher.mark-debug("o")

#let dotmark = cetz.draw.circle.with(radius: 1.5pt, stroke: none)

#import "marks.typ": draw-mark, DEFAULT_MARKS
#import "edges.typ"

#context cetz.canvas(length: 1cm, {
  import cetz.draw

  draw.rotate(20deg)
  draw.scale(x: -1)
  let a = draw.circle((0,1), fill: yellow.transparentize(50%), stroke: none)
  let b = draw.rect((5,0), (2,1))
  let c = draw.rect((4,4), (3,2), fill: yellow.transparentize(50%), stroke: none)
  a + b + c


  edges.draw-edge-with-snapping((5,3), (0,1),
    snap-to: (c, a),
    draw: (a, b) => draw.arc-through(a, (2,3), b),
    debug: 1,
    marks: ("cone", ">", "<<<"),
  )
  edges.draw-edge-with-snapping((5,3), (0,1),
    snap-to: (c, a),
    draw: (a, b) => draw.arc-through(a, (1,3), b, stroke: 2pt),
    debug: 1,
    marks: ("o", "stealth", "o"),
  )

  flexigrid(
    {
      node((0,0), none)
      node((5,5), none)
    },
    debug: 1,
    gutter: 1cm,
  )
})

== Marks

#import "marks.typ" as _marks



#context cetz.canvas({
  import cetz.draw

  draw.set-style(stroke: 2pt)
  draw.rect((-1,-1), (1,1))

  draw.get-ctx(ctx => {
    let path = draw.arc((0,0), start: 180deg, delta: -135deg, radius: 2)
    path
    _marks.draw-marks-on-path(ctx, path, (none, ">"))
  })

  _marks.with-marks(draw.line((0,2), (3,0), stroke: red), "-latex")
})

= demo

#diagram({
  node((10,0), [Hello], shape: shapes.rect, inset: (bottom: 10pt))
  node((9,-1), circle(), shape: shapes.circle, name: "A")
  node((11,-1), circle(), shape: shapes.circle)
  cetz.draw.content("A.east", [Hello], anchor: "west")
  // edge(((10,0), (11,-1)), draw: (a, b) => cetz.draw.line(a, b))
}, gutter: 1cm, debug: true)



