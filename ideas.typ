#import "exports.typ": flexigrid, diagram, node, edge, shapes, cetz, utils

#set page(width: 13cm)
#show heading: it => pad(it, y: 2em)

#import "marks.typ"


#lorem(20)
#cetz.canvas({
  import cetz.draw

  flexigrid(debug: 0, {
    node((0,0), $G$)
    edge((0,0), "->", (1,0), name: "foo")
    edge((0,0), "->>", (0,-1))
    node((1,0), $im(f)$)
    edge((0,-1), "hook-->", (1,0), name: "bar")
    node((0,-1), $G slash ker(f)$)
    marks.with-marks(cetz.draw.bezier("foo.50%", "bar", (1.7,1.4)), "*-o", shrink: false)
    cetz.draw.circle("foo.75%", radius: 1pt, stroke: yellow)
  })
})


#cetz.canvas({
  import cetz.draw

  node((5,5), [fred], stroke: 1pt)
  flexigrid(
    name: "a",
    gutter: 1cm,
  {
    node((1,0), $"up"(bold(x))^2$, name: "bi", stroke: .5pt)
    edge((0,0), (1,0), "->")
    draw.set-style(node: (stroke: blue + 1pt, fill: yellow.transparentize(50%)))
    draw.set-style(edge: (stroke: blue + 2pt))
    node((0,1), [Hello\ World], inset: 3mm, name: "hi", stroke: teal, outset: 5pt)
    node((0,0), [CeTZ], inset: 5pt, name: "hi", fill: lime, extrude: (0, -2pt,))
    draw.circle("bi.south-east", radius: 0.2, stroke: yellow)
    edge((0,1), (1,1), (2,0), "->")
    marks.with-marks(draw.line("bi.north-east", (5,2)), "->")
  })
    edge((0,3), "latex-o-|>", (3,3))

})

#lorem(7)

#diagram(debug: 3, {
  import cetz.draw
  node((0,0), $ (a z + b)/(c z + d) $)
  edge((0,0), "<->", (1,1), snap-to: (auto, auto))
  node((1,1), [hi there], name: "a", stroke: green, shape: shapes.circle)
  draw.circle("a.45deg", radius: 5pt, fill: yellow)
  draw.get-ctx(ctx => {
    draw.circle((ctx.flexigrid)((0,.5)), radius: 5pt, fill: blue)
  })
  node((2,0), inset: 4mm, fill: black, shape: shapes.circle, name: "a")
  draw.content("a.east", $f(x)$, anchor: "west", padding: 5pt)
})


#let BASE_EDGE_STYLE = (
  marks: (),
  stroke: (thickness: 0.048em),
)
#cetz.canvas({
  cetz.draw.get-ctx(ctx => {
    let styles = cetz.styles.resolve(
      ctx.style,
      base: BASE_EDGE_STYLE,
      merge: (edge: (stroke: (paint: red), dash: "dashed")),
      root: "edge",
    )
    cetz.draw.content((0,0), [#styles])
  })
})
