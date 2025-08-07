#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#import "marks.typ"

#cetz.canvas({
  import cetz.draw

  node((5,5), [fred], stroke: 1pt)
  flexigrid(
    name: "a",
    debug: 0,
    gutter: 1cm,
  {
    node((1,0), $"up"(bold(x))^2$, name: "bi", stroke: .5pt)
    edge((0,0), (1,0), "->")
    draw.set-style(node: (stroke: blue + 1pt, fill: yellow.transparentize(50%)))
    draw.set-style(edge: (stroke: blue + 2pt))
    node((0,1), [Hello\ World], inset: 3mm, name: "hi", stroke: teal, outset: 5pt)
    node((0,0), [CeTZ], inset: 5pt, name: "hi", fill: lime, extrude: (0, 2pt,))
    draw.circle("bi.south-east", radius: 0.2, stroke: yellow)
    edge((0,1), (1,1), (2,0), "->")
    marks.with-marks(draw.line("bi.north-east", (5,2)), "->")
  })
    edge((0,3), "latex-o-|>", (3,3))

})

#diagram(debug: true, {
  import cetz.draw
  node((0,0), $ (a z + b)/(c z + d) $)
  node((1,1), circle(), name: "a")
  draw.circle("a.east", radius: 5pt, fill: yellow)
  draw.get-ctx(ctx => {
    draw.circle((ctx.flexigrid)((0,.5)), radius: 5pt, fill: blue)
  })
})
