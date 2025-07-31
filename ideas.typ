= FlexiCeTZ

Ideas for elastic coordinates.

We want an interface something like this:

```typ
#cetz.canvas({
  import cetz.draw
  import flexicetz: elastic-grid, node

  elastic-grid({
    node((0,0), draw.circle((0,0), radius: 5pt, fill: blue))
    node((1,1), draw.square((0,0), radius: 5pt, fill: blue))
  },
    debug: 1, // show elastic gridlines
    grid: auto,
    pos: (0, 0) // cetz coordinate
    anchor: "north-west"
  )
})

```

#import "@preview/cetz:0.4.1"

#import "utils.typ": *

#let grid = (
  centers: (x: (0cm, 1cm, 3cm, 4.5cm), y: (0cm, 0.5cm, 2cm)),
  origin: (x: -1, y: 10),
  x-min: -1,
  y-min: 10,
)

#let uv-to-xy(grid, uv) = {
  let (u, v) = uv
  let (i, j) = (u - grid.x-min, v - grid.y-min)
  (interp(grid.centers.x, i), interp(grid.centers.y, j))
}

#let node(grid, pos, label) = {
  let size = measure(label)
  let xy = uv-to-xy(grid, pos)
  cetz.draw.rect((to: xy, rel: (size.width/2, size.height/2)), (to: xy, rel: (-size.width/2, -size.height/2)))
  cetz.draw.content(xy, label)
}
#let draw-flexigrid(grid) = {
  let s = 3pt
  cetz.draw.floating({
    cetz.draw.set-style(stroke: red.transparentize(50%))
    for (i, x) in grid.centers.x.enumerate() {
      for (j, y) in grid.centers.y.enumerate() {
        cetz.draw.line((to: (x, y), rel: (0, -s)), (to: (x, y), rel: (0, +s)))
        cetz.draw.line((to: (x, y), rel: (-s, 0)), (to: (x, y), rel: (+s, 0)))
        let (w, h) = (grid.col-widths.at(i), grid.row-heights.at(j))

        cetz.draw.rect((x - w/2, y - h/2), (x + w/2, y + h/2), stroke: red.transparentize(85%))
      }
    }

    for (i, x) in grid.centers.x.enumerate() {
      let coord = i + grid.x-min
      cetz.draw.content((x, -0.5em), text(10pt, red, raw(str(coord))), anchor: "north")
      let w = grid.col-widths.at(i)
      cetz.draw.line((x - w/2, 0), (x + w/2, 0), stroke: 2pt + red)
    }
    for (j, y) in grid.centers.y.enumerate() {
      let coord = j + grid.y-min
      cetz.draw.content((-0.5em, y), text(10pt, red, raw(str(coord))), anchor: "east")
      let h = grid.row-heights.at(j)
      cetz.draw.line((0, y - h/2), (0, y + h/2), stroke: 2pt + red)
    }
  })

}

// #context cetz.canvas({
//   import cetz.draw
  
//   draw-flexigrid(grid)
//   node(grid, (1,12))[Hello Worlds]
//   node(grid, (-1,10))[Hello Worlds]
// })

#import "elastic-grid.typ": *
#let elastic-layout(objects, gutter: 0, debug: 0) = {
  cetz.draw.get-ctx(ctx => {
    let objects = objects.map(obj => {
      obj + (size: cetz.util.measure(ctx, obj.content))
    })

    let grid = grid-from-rects(objects, gutter: gutter)

    if debug > 0 {
      cetz.draw.group(draw-flexigrid(grid))
    }

    for object in objects {
      let c = uv-to-xy(grid, object.pos)
      let (w, h) = object.size
      cetz.draw.content(c, text(top-edge: "cap-height", bottom-edge: "baseline", object.content))
      cetz.draw.rect((to: c, rel: (-w/2, -h/2)), (to: c, rel: (w/2, h/2)), name: object.name)
    }

  })
}

#cetz.draw.content

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
  elastic-layout({
    node((0,0), $U$, name: "A")
    node((1,1), $V times W$, name: "B")
    node((2,0), $frak(B)$)
  }, gutter: 2, debug: 1)
  draw.line("A.north-east", "B.west")
})

#box(fill: luma(96%), fig)