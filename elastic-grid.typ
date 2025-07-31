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

  let (n-cols, n-rows) = (x-max - x-min + 1, y-max - y-min + 1)

  let (col-widths, row-heights) = ((0,)*n-cols, (0,)*n-rows)

  for rect in rects {
    let (x, y) = rect.pos
    let (i, j) = (x - x-min, y - y-min)

    let (w, h) = rect.size
    let (i-floor, j-floor) = (calc.floor(i), calc.floor(j))
    col-widths.at(i-floor) = calc.max(col-widths.at(i-floor), w*(1 - i + i-floor))
    if i-floor < n-cols - 1 {
      col-widths.at(i-floor + 1) = calc.max(col-widths.at(i-floor + 1), w*(i - i-floor))
    }
    row-heights.at(j-floor) = calc.max(row-heights.at(j-floor), h*(1 - j + j-floor))
    if j-floor < n-rows - 1 {
      row-heights.at(j-floor + 1) = calc.max(row-heights.at(j-floor + 1), h*(j - j-floor))
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