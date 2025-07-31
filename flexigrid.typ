#import "utils.typ"
#import "@preview/cetz:0.4.1"

#let grid-from-rects(rects, gutter: 0) = {
  let (x-min, x-max) = (0, 0)
  let (y-min, y-max) = (0, 0)

  for rect in rects {
    let (x, y) = rect.pos
    if x < x-min { x-min = x }
    if x-max < x { x-max = x }
    if y < y-min { y-min = y }
    if y-max < y { y-max = y }
  }

  (x-min, x-max) = (calc.floor(x-min), calc.ceil(x-max))
  (y-min, y-max) = (calc.floor(y-min), calc.ceil(y-max))

  let (n-cols, n-rows) = (x-max - x-min + 1, y-max - y-min + 1)
  let (col-widths, row-heights) = ((0,)*n-cols, (0,)*n-rows)

  for rect in rects {
    let (x, y) = rect.pos
    let (i, j) = (x - x-min, y - y-min)
    let (i-floor, j-floor) = (calc.floor(i), calc.floor(j))
    let (i-fract, j-fract) = (calc.fract(i), calc.fract(j))

    let (w, h) = rect.size

    col-widths.at(i-floor) = calc.max(col-widths.at(i-floor), w*(1 - i-fract))
    if i-floor + 1 < n-cols {
      col-widths.at(i-floor + 1) = calc.max(col-widths.at(i-floor + 1), w*i-fract)
    }

    row-heights.at(j-floor) = calc.max(row-heights.at(j-floor), h*(1 - j-fract))
    if j-floor + 1 < n-rows {
      row-heights.at(j-floor + 1) = calc.max(row-heights.at(j-floor + 1), h*j-fract)
    }
  }

  let centers = (x: (), y: ())
  let x = 0
  for (i, col) in col-widths.enumerate() {
    x += col
    centers.x.push(x - col/2 + i*gutter)
  }
  let y = 0
  for (i, row) in row-heights.enumerate() {
    y += row
    centers.y.push(y - row/2 + i*gutter)
  }

  (
    x-min: x-min,
    x-max: x-max,
    y-min: y-min,
    y-max: y-max,
    col-widths: col-widths,
    row-heights: row-heights,
    centers: centers,
  )
}

#let uv-to-xy(grid, uv) = {
  let (u, v) = uv
  let (i, j) = (u - grid.x-min, v - grid.y-min)
  (utils.interp(grid.centers.x, i), utils.interp(grid.centers.y, j))
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


#let flexigrid(objects, gutter: 0, debug: 0) = {
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