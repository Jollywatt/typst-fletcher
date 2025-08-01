#import "utils.typ"
#import "deps.typ": cetz
#import "nodes.typ"


#let cell-sizes-from-rects(rects) = {
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
  let (col-sizes, row-sizes) = ((0,)*n-cols, (0,)*n-rows)

  for rect in rects {
    let (x, y) = rect.pos
    let (i, j) = (x - x-min, y - y-min)
    let (i-floor, j-floor) = (calc.floor(i), calc.floor(j))
    let (i-fract, j-fract) = (calc.fract(i), calc.fract(j))

    let (w, h) = rect.size

    col-sizes.at(i-floor) = calc.max(col-sizes.at(i-floor), w*(1 - i-fract))
    if i-floor + 1 < n-cols {
      col-sizes.at(i-floor + 1) = calc.max(col-sizes.at(i-floor + 1), w*i-fract)
    }

    row-sizes.at(j-floor) = calc.max(row-sizes.at(j-floor), h*(1 - j-fract))
    if j-floor + 1 < n-rows {
      row-sizes.at(j-floor + 1) = calc.max(row-sizes.at(j-floor + 1), h*j-fract)
    }
  }

  return (
    x-min: x-min,
    x-max: x-max,
    y-min: y-min,
    y-max: y-max,
    col-sizes: col-sizes,
    row-sizes: row-sizes,
  )
}

#let cell-centers-from-sizes((col-sizes, row-sizes), gutter: 0) = {
  let centers = (x: (), y: ())

  let x = 0
  for (i, col) in col-sizes.enumerate() {
    x += col
    centers.x.push(x - col/2 + i*gutter)
  }
  let y = 0
  for (i, row) in row-sizes.enumerate() {
    y += row
    centers.y.push(y - row/2 + i*gutter)
  }

  return centers
}


#let interp-grid-cell(grid, (x, y)) = {
  let (i, j) = (x - grid.x-min, y - grid.y-min)
  (
    x: utils.interp(grid.centers.x, i),
    y: utils.interp(grid.centers.y, j),
    w: utils.interp(grid.col-sizes, i),
    h: utils.interp(grid.row-sizes, j),
  )
}


#let draw-flexigrid(grid) = {
  let s = 3pt
  cetz.draw.floating({
    cetz.draw.set-style(stroke: red.transparentize(50%))
    for (i, x) in grid.centers.x.enumerate() {
      for (j, y) in grid.centers.y.enumerate() {
        let (w, h) = (grid.col-sizes.at(i), grid.row-sizes.at(j))
        cetz.draw.circle((x, y), radius: 0.8pt, fill: red, stroke: none)
        cetz.draw.rect((x - w/2, y - h/2), (x + w/2, y + h/2), stroke: red.transparentize(85%))
      }
    }

    for (i, x) in grid.centers.x.enumerate() {
      let coord = i + grid.x-min
      cetz.draw.content((x, -0.5em), text(10pt, red, raw(str(coord))), anchor: "north")
      let w = grid.col-sizes.at(i)
      cetz.draw.line((x - w/2, 0), (x + w/2, 0), stroke: 2pt + red)
    }
    for (j, y) in grid.centers.y.enumerate() {
      let coord = j + grid.y-min
      cetz.draw.content((-0.5em, y), text(10pt, red, raw(str(coord))), anchor: "east")
      let h = grid.row-sizes.at(j)
      cetz.draw.line((0, y - h/2), (0, y + h/2), stroke: 2pt + red)
    }
  })

}

#let interpret-rowcol-spec(input) = {
  if input == auto { return i => auto }
  if type(input) == array { return i => input.at(i) }
  if type(input) == function { return input }
  return i => input
}

#let apply-rowcol-spec(fn, defaults) = {
  for (i, col) in defaults.enumerate() {
    let given = (fn)(i)
    if given not in (none, auto) {
      defaults.at(i) = cetz.util.resolve-number(ctx, given)
    }
  }
  return defaults
}


#let flexigrid(
  objects,
  gutter: 0,
  debug: 0,
  origin: (0,0),
  columns: auto,
  rows: auto,
  name: none,
) = {
  let col-spec = interpret-rowcol-spec(columns)
  let row-spec = interpret-rowcol-spec(rows)

  objects = utils.as-array(objects)


  let objs = cetz.draw.get-ctx(ctx => {
    let gutter = cetz.util.resolve-number(ctx, gutter)

    let (_, origin) = cetz.coordinate.resolve(ctx, origin)
    cetz.draw.translate(origin)


    // phase 1: measure the sizes of all nodes
    let objects = objects.map(obj => {
      if utils.is-node(obj) {
        obj + (size: cetz.util.measure(ctx, obj.content))
      } else {
        obj
      }
    })

    // phase 2: compute the cell sizes and positions in flexigrid
    let grid = cell-sizes-from-rects(objects.filter(utils.is-node))
    grid.col-sizes = apply-rowcol-spec(col-spec, grid.col-sizes)
    grid.row-sizes = apply-rowcol-spec(row-spec, grid.row-sizes)
    grid.centers = cell-centers-from-sizes(grid, gutter: gutter)

    if debug > 0 {
      cetz.draw.group(draw-flexigrid(grid))
    }

    // phase 3: draw objects at resolved locations
    for object in objects {
      if utils.is-node(object) {
        let cell = interp-grid-cell(grid, object.pos)
        nodes.draw-node-in-cell(object, cell)
      } else {
        (object,)
      }
    }

  })

  cetz.draw.group(objs, name: name)
}

#let diagram(..args) = cetz.canvas(flexigrid(..args))
