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
)

#let uv-to-xy(grid, uv) = {
  let (u, v) = uv
  let (i, j) = (u - grid.origin.x, v - grid.origin.y)
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
        cetz.draw.line((x, y - s), (x, y + s))
        cetz.draw.line((x - s, y), (x + s, y))
      }
    }

    for (i, x) in grid.centers.x.enumerate() {
      let coord = i + grid.origin.x
      cetz.draw.content((x, -0.5em), text(0.7em, red, raw(str(coord))), anchor: "north")
    }
    for (j, y) in grid.centers.y.enumerate() {
      let coord = j + grid.origin.y
      cetz.draw.content((-0.5em, y), text(0.7em, red, raw(str(coord))), anchor: "east")
    }
  })
}

#context cetz.canvas({
  import cetz.draw
  

  draw-flexigrid(grid)
  node(grid, (1,12))[Hello Worlds]
  node(grid, (-1,10))[Hello Worlds]
})

