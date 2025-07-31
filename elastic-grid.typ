#import "utils.typ"

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

  x-min = calc.floor(x-min)
  x-max = calc.ceil(x-max)
  y-min = calc.floor(y-min)
  y-max = calc.ceil(y-max)

  let (cols, rows) = (x-max - x-min + 1, y-max - y-min + 1)

  let (col-widths, row-heights) = ((gutter,)*cols, (gutter,)*rows)

  for rect in rects {
    let (x, y) = rect.pos
    let (i, j) = (x - x-min, y - y-min)

    let (w, h) = rect.size
    col-widths.at(i) = calc.max(col-widths.at(i), w)
    row-heights.at(j) = calc.max(row-heights.at(j), h)
  }

  let centers = (x: (), y: ())
  // for col in col-widths { centers.x.push(centers.x.at(-1) - col/2) }
  // for row in row-heights { centers.y.push(centers.y.at(-1) - row/2) }
  // 
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