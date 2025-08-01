= FlexiCeTZ

#import "@preview/cetz:0.4.1"

#import "utils.typ": *

#let grid = (
  centers: (x: (0cm, 1cm, 3cm, 4.5cm), y: (0cm, 0.5cm, 2cm)),
  origin: (x: -1, y: 10),
  x-min: -1,
  y-min: 10,
)


#let node(grid, pos, label) = {
  let size = measure(label)
  let xy = uv-to-xy(grid, pos)
  cetz.draw.rect((to: xy, rel: (size.width/2, size.height/2)), (to: xy, rel: (-size.width/2, -size.height/2)))
  cetz.draw.content(xy, label)
}

#import "flexigrid.typ": *



#let node(pos, content, name: none) = {
  ((
    class: "node",
    pos: pos,
    content: content,
    name: name,
  ),)
}

#v(1cm)
#set text(3em)

#let fig = cetz.canvas({
  import cetz.draw
  flexigrid({
    node((0,0), $U$, name: "A")
    node((1,1), $ a + b/c $, name: "B")
    node((2,0), $ frak(B)/oo $)
  },
    gutter: 3pt,
    debug: 1,
    origin: (0,0),
    columns: i => if i == 1 { 4cm }
  )
  draw.line("A.north-east", "B.west")
  draw.circle((0,0), radius: 5mm)
})

#box(fill: luma(96%), fig)