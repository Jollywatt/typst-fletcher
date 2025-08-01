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
#set text(3em)

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

#box(fill: luma(96%), fig)
