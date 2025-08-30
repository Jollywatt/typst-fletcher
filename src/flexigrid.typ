#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level

/// From an array of rectangles, each of the form
/// `(pos: array, size: array, weight: number)`,
/// calculate the sizes of flexigrid cells.
/// 
/// Rectangle positions can be fractional.
#let cell-sizes-from-rects(rects) = {
  let (u-min, u-max) = (float.inf, -float.inf)
  let (v-min, v-max) = (float.inf, -float.inf)

  for rect in rects {
    let (u, v) = rect.pos
    if u < u-min { u-min = u }
    if u-max < u { u-max = u }
    if v < v-min { v-min = v }
    if v-max < v { v-max = v }
  }
  if float.is-infinite(u-min) { u-min = 0}
  if float.is-infinite(u-max) { u-max = 0}
  if float.is-infinite(v-min) { v-min = 0}
  if float.is-infinite(v-max) { v-max = 0}

  (u-min, u-max) = (calc.floor(u-min), calc.ceil(u-max))
  (v-min, v-max) = (calc.floor(v-min), calc.ceil(v-max))

  let (n-cols, n-rows) = (u-max - u-min + 1, v-max - v-min + 1)
  let (col-sizes, row-sizes) = ((0,)*n-cols, (0,)*n-rows)

  for node in rects {
    let (u, v) = node.pos
    let (i, j) = (u - u-min, v - v-min)
    let (i-floor, j-floor) = (calc.floor(i), calc.floor(j))
    let (i-fract, j-fract) = (calc.fract(i), calc.fract(j))

    let (w, h) = node.size
    w *= node.weight
    h *= node.weight

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
    u-min: u-min,
    u-max: u-max,
    v-min: v-min,
    v-max: v-max,
    col-sizes: col-sizes,
    row-sizes: row-sizes,
  )
}

#let cell-centers-from-sizes((col-sizes, row-sizes), gutter: 0) = {
  let col-centers = ()
  let row-centers = ()

  let x = 0
  for (i, col) in col-sizes.enumerate() {
    x += col
    col-centers.push(x - col/2 + i*gutter)
  }
  let y = 0
  for (i, row) in row-sizes.enumerate() {
    y += row
    row-centers.push(y - row/2 + i*gutter)
  }

  return (
    col-centers: col-centers,
    row-centers: row-centers,
    x-min: 0,
    y-min: 0,
    x-max: col-centers.at(-1) + col-sizes.at(-1)/2,
    y-max: row-centers.at(-1) + row-sizes.at(-1)/2,
  )
}


#let interpolate-grid-point(grid, coord) = {
  let (u, v, ..) = coord
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  (
    utils.interp(grid.col-centers, i, spacing: 1),
    utils.interp(grid.row-centers, j, spacing: 1),
  )
}


#let draw-flexigrid(grid, debug: true) = {
  let draw-lines = debug-level(debug, "grid.lines")
  let draw-coords = debug-level(debug, "grid.coords")
  let draw-cells = debug-level(debug, "grid.cells")

  cetz.draw.floating({
    cetz.draw.set-style(stroke: (paint: red.transparentize(60%)))

    for (i, x) in grid.col-centers.enumerate() {
      if draw-lines {
        cetz.draw.line((x, grid.y-min), (x, grid.y-max), stroke: (thickness: 0.5pt))
      }
      if draw-coords {
        let coord = i + grid.u-min
        cetz.draw.content((x, -4pt), text(10pt, red, raw(str(coord))), anchor: "north")
      }
      if draw-cells {
        let w = grid.col-sizes.at(i)
        cetz.draw.line((x - w/2, 0), (x + w/2, 0), stroke: (thickness: 1pt))
      }
    }
    for (j, y) in grid.row-centers.enumerate() {
      if draw-lines {
        cetz.draw.line((grid.x-min, y), (grid.x-max, y), stroke: (thickness: 0.5pt))
      }
      if draw-coords {
        let coord = j + grid.v-min
        cetz.draw.content((-4pt, y), text(10pt, red, raw(str(coord))), anchor: "east")
      }
      if draw-cells {
        let h = grid.row-sizes.at(j)
        cetz.draw.line((0, y - h/2), (0, y + h/2), stroke: (thickness: 1pt))
      }
    }

    if draw-cells {
      for (i, x) in grid.col-centers.enumerate() {
        for (j, y) in grid.row-centers.enumerate() {
          let (w, h) = (grid.col-sizes.at(i), grid.row-sizes.at(j))
          cetz.draw.rect((x - w/2, y - h/2), (x + w/2, y + h/2), stroke: red.transparentize(80%) + 0.5pt)
        }
      }
    }
  })

}

/// A row/column specifier can be
/// - `auto`, meaning all row/columns are automatically sized
/// - a number of length, specifying the size
/// - an array of the above, specifying each row/column individually
/// - a function taking the index and returning a size, `none` or `auto`
#let interpret-rowcol-spec(input) = {
  if input == auto { return i => auto }
  if type(input) == array { return i => input.at(i) }
  if type(input) == function { return input }
  return i => input
}

#let apply-rowcol-spec(ctx, fn, defaults) = {
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
  gutter: 1,
  origin: (0,0),
  columns: auto,
  rows: auto,
  name: none,
  debug: false,
) = {
  let col-spec = interpret-rowcol-spec(columns)
  let row-spec = interpret-rowcol-spec(rows)

  objects = utils.as-array(objects)


  cetz.draw.get-ctx(ctx => {
    let gutter = cetz.util.resolve-number(ctx, gutter)
    let (_, origin) = cetz.coordinate.resolve(ctx, origin)
    cetz.draw.translate(origin)

    ctx.shared-state.fletcher = (
      pass: "layout",
      nodes: (),
      edges: (),
      current: (node: 0, edge: 0),
    )

    // run layout pass to retrieve fletcher objects
    let layout-pass = cetz.process.many(ctx, objects)
    let (nodes, edges) = layout-pass.ctx.shared-state.fletcher

    // compute cell sizes and positions in flexigrid
    let grid = cell-sizes-from-rects(nodes)
    grid.col-sizes = apply-rowcol-spec(ctx, col-spec, grid.col-sizes)
    grid.row-sizes = apply-rowcol-spec(ctx, row-spec, grid.row-sizes)
    grid += cell-centers-from-sizes(grid, gutter: gutter)

    // provide extra context used by objects
    (ctx => {
      ctx.shared-state.fletcher = (
        pass: "final",
        nodes: nodes,
        edges: edges,
        current: (node: 0, edge: 0), // index of current object
        flexigrid: grid,
        debug: debug,
      )
      return (ctx: ctx)
    },)

    objects

    if debug-level(debug, "grid") {
      cetz.draw.group(draw-flexigrid(grid, debug: debug))
    }

  })
}

#let diagram(..args) = cetz.canvas(flexigrid(..args))
