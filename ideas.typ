#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#import "marks.typ"

#cetz.canvas({
  import cetz.draw

  flexigrid(
    name: "a",
    debug: none,
    gutter: 1,
  {
    node((1,0), $"up"(bold(x))^2$, inset: 5pt, name: "bi", stroke: .5pt)
    node((0,1), [Hello\ World], inset: 5pt, name: "hi", stroke: teal)
    draw.set-style(node: (stroke: blue + 1pt, fill: yellow))
    node((0,0), [CeTZ], inset: 5pt, name: "hi", fill: yellow, extrude: (0, 2pt,))
    draw.circle("bi.north-west", radius: 0.2, stroke: yellow)
    edge((0,1), (2,1), (2,0), "->")
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
