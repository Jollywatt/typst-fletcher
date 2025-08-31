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

#let draw-xy-grid(origin, flexigrid) = {
  let (x-min, x-max, y-min, y-max) = flexigrid
  let coord-label(x) = text(blue, 0.8em, raw(str(x)))
  cetz.draw.group({
    cetz.draw.grid((x-min, y-min), (x-max, y-max), stroke: blue.transparentize(50%) + 0.5pt)
    for x in range(calc.floor(x-min), calc.floor(x-max) + 1) {
      cetz.draw.content((x, y-min), coord-label(x), anchor: "north", padding: .5em)
    }
    for y in range(calc.floor(y-min), calc.floor(y-max) + 1) {
      cetz.draw.content((x-min, y), coord-label(y), anchor: "east", padding: .5em)
    }
  })
}

#let draw-flexigrid(grid, debug: true, tint: red) = {
  let draw-lines = debug-level(debug, "grid.lines")
  let draw-coords = debug-level(debug, "grid.coords")
  let draw-cells = debug-level(debug, "grid.cells")

  if not (draw-lines or draw-coords or draw-cells) { return }

  cetz.draw.floating({
    cetz.draw.set-style(stroke: (paint: tint.transparentize(60%)))

    for (i, x) in grid.col-centers.enumerate() {
      if draw-lines {
        cetz.draw.line((x, grid.y-min), (x, grid.y-max), stroke: (thickness: 0.5pt))
      }
      if draw-coords {
        let coord = i + grid.u-min
        cetz.draw.content((x, -4pt), text(10pt, tint, raw(str(coord))), anchor: "north")
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
        cetz.draw.content((-4pt, y), text(10pt, tint, raw(str(coord))), anchor: "east")
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
          cetz.draw.rect((x - w/2, y - h/2), (x + w/2, y + h/2), stroke: tint.transparentize(80%) + 0.5pt)
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


#let with-coordinate-resolver(ctx, resolver) = {
  if type(ctx.resolve-coordinate) == array {
    ctx.resolve-coordinate.push(resolver)
  } else {
    ctx.resolve-coordinate = (resolver,)
  }
  return ctx
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
    // cetz.draw.translate(origin) // todo

    ctx.shared-state.fletcher = (
      pass: "layout",
      nodes: (),
      edges: (),
      current: (node: 0, edge: 0),
    )

    // for the layout pass, we resolve uv coords by treating them as xy
    let layout-pass-ctx = with-coordinate-resolver(ctx, (ctx, c) => {
      if type(c) == dictionary {
        if "uv" in c { return c.uv }
        if "xy" in c { return c.xy }
      } 
      return c
    })

    // run layout pass to retrieve fletcher objects
    let layout-pass = cetz.process.many(layout-pass-ctx, objects)
    let (nodes, edges) = layout-pass.ctx.shared-state.fletcher

    // compute grid cell sizes and positions
    let grid = cell-sizes-from-rects(nodes)
    grid.col-sizes = apply-rowcol-spec(ctx, col-spec, grid.col-sizes)
    grid.row-sizes = apply-rowcol-spec(ctx, row-spec, grid.row-sizes)
    grid += cell-centers-from-sizes(grid, gutter: gutter)

    let uv-resolver(ctx, c) = {
      if type(c) == dictionary {
        if "uv" in c { return utils.uv-to-xy(grid, c.uv) }
        if "xy" in c { return c.xy }
        if "rel" in c and type(c.rel) == array and c.rel.all(x => type(x) in (int, float)) {
          let (_, prev-xy) = cetz.coordinate.resolve(ctx, c.at("to", default: ()))
          let prev-uv = utils.xy-to-uv(grid, prev-xy)
          let new-uv = cetz.vector.add(prev-uv, c.rel)
          return utils.uv-to-xy(grid, new-uv)
        }
      }
      return c
    }

    let (_, ..node-coords) = cetz.coordinate.resolve(with-coordinate-resolver(ctx, uv-resolver),
      ..nodes.map(n => utils.interpret-as-uv(n.pos)))

    nodes = nodes.zip(node-coords).map(((n, c)) => {
      n.pos = c
      n
    })

    // provide extra context used by objects
    (ctx => {
      ctx = with-coordinate-resolver(ctx, uv-resolver)
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

    // if debug-level(debug, "grid") {
    cetz.draw.group(draw-flexigrid(grid, debug: debug))
    // }

    if debug-level(debug, "grid.xy") {
      draw-xy-grid(origin, grid)
    }


    // destroy flexigrid context (use group?)
    (ctx => {
      ctx.shared-state.remove("fletcher")
      return (ctx: ctx)
    },)

  })
}

#let diagram(..args) = cetz.canvas(flexigrid(..args))
