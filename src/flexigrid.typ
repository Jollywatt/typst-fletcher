#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-group

/// Calculate the appropriate sizes `w0` and `w1` of adjacent cells
/// when placing a node of width `W` at position `0 <= t <= 1 ` with
/// cell gutter `g`.
/// https://jollywatt.github.io/flexigrid
#let cell-sizer(W, w0, w1, t, g) = {
  if t == 0 { return (W, 0) }
  let x0 = -t*calc.max(
    (2*g + w1 + w0),
    (2*g + w1 + W)/(1 + t),
    (2*g + W + w0)/(2 - t),
    (2*g + 2*W)/2,
  )
  return (x0 + W, W - (t - 1)/t*x0)
}

/// From an array of rectangles, each of the form
/// `(pos: array, size: array, weight: number)`,
/// calculate the sizes of flexigrid cells.
/// 
/// Rectangle positions can be fractional.
#let cell-sizes-from-rects(rects, (col-gutter, row-gutter)) = {
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

  // add extra zero-size padding rows/cols around content
  // to make coordinate extrapolation beyond bounds correct
  u-min -= 1
  v-min -= 1
  u-max += 1
  v-max += 1

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

    let (w0, w1) = (col-sizes.at(i-floor), col-sizes.at(i-floor + 1))
    let (w0new, w1new) = cell-sizer(w, w0, w1, i-fract, col-gutter)
    col-sizes.at(i-floor) = calc.max(w0, w0new)
    col-sizes.at(i-floor + 1) = calc.max(w1, w1new)

    let (h0, h1) = (row-sizes.at(j-floor), row-sizes.at(j-floor + 1))
    let (h0new, h1new) = cell-sizer(h, h0, h1, j-fract, row-gutter)
    row-sizes.at(j-floor) = calc.max(h0, h0new)
    row-sizes.at(j-floor + 1) = calc.max(h1, h1new)
  }

  return (
    u-min: u-min,
    u-max: u-max,
    v-min: v-min,
    v-max: v-max,
    col-sizes: col-sizes,
    row-sizes: row-sizes,
    col-gutter: col-gutter,
    row-gutter: row-gutter,
  )
}

#let cell-centers-from-sizes(grid) = {
  let col-centers = ()
  let row-centers = ()

  let x = 0
  for (i, col) in grid.col-sizes.enumerate() {
    x += col
    col-centers.push(x - col/2 + i*grid.col-gutter)
  }
  let y = 0
  for (i, row) in grid.row-sizes.enumerate() {
    y += row
    row-centers.push(y - row/2 + i*grid.row-gutter)
  }

  return (
    col-centers: col-centers,
    row-centers: row-centers,
    x-min: col-centers.at(1) - grid.col-sizes.at(1)/2,
    y-min: row-centers.at(1) - grid.row-sizes.at(1)/2,
    x-max: col-centers.at(-2) + grid.col-sizes.at(-2)/2,
    y-max: row-centers.at(-2) + grid.row-sizes.at(-2)/2,
  )
}

#let draw-xy-grid(origin, flexigrid) = {
  let (x-min, x-max, y-min, y-max) = flexigrid
  let (x-floor, y-floor) = (calc.floor(x-min), calc.floor(y-min))
  let coord-label(x) = text(blue, 0.8em, raw(str(x)))
  debug-group({
    cetz.draw.grid((x-floor, y-floor), (x-max, y-max), stroke: blue.transparentize(50%) + 0.5pt)
    for x in range(x-floor, calc.floor(x-max) + 1) {
      cetz.draw.content((x, y-floor), coord-label(x), anchor: "north", padding: .5em)
    }
    for y in range(y-floor, calc.floor(y-max) + 1) {
      cetz.draw.content((x-floor, y), coord-label(y), anchor: "east", padding: .5em)
    }
  })
}

#let draw-flexigrid(grid, debug: true, tint: red) = {
  let draw-lines = debug-level(debug, "grid.lines")
  let draw-coords = debug-level(debug, "grid.coords")
  let draw-cells = debug-level(debug, "grid.cells")

  if not (draw-lines or draw-coords or draw-cells) { return }

  debug-group({
    cetz.draw.set-style(
      stroke: (paint: tint.transparentize(60%)),
      content: (padding: 4pt),
    )

    // skip the first/last zero-size padding rows/cols

    for (i, x) in grid.col-centers.enumerate().slice(1,-1) {
      if draw-lines {
        cetz.draw.line((x, grid.y-min), (x, grid.y-max), stroke: (thickness: 0.5pt))
      }
      if draw-coords {
        let coord = i + grid.u-min
        cetz.draw.content((x, grid.y-min), text(10pt, tint, raw(str(coord))), anchor: "north")
      }
      if draw-cells {
        let w = grid.col-sizes.at(i)
        cetz.draw.line((x - w/2, grid.y-min), (x + w/2, grid.y-min), stroke: (thickness: 1pt))
      }
    }
    for (j, y) in grid.row-centers.enumerate().slice(1,-1) {
      if draw-lines {
        cetz.draw.line((grid.x-min, y), (grid.x-max, y), stroke: (thickness: 0.5pt))
      }
      if draw-coords {
        let coord = j + grid.v-min
        cetz.draw.content((grid.x-min, y), text(10pt, tint, raw(str(coord))), anchor: "east")
      }
      if draw-cells {
        let h = grid.row-sizes.at(j)
        cetz.draw.line((grid.x-min, y - h/2), (grid.x-min, y + h/2), stroke: (thickness: 1pt))
      }
    }

    if draw-cells {
      for (i, x) in grid.col-centers.enumerate().slice(1, -1) {
        for (j, y) in grid.row-centers.enumerate().slice(1, -1) {
          let (w, h) = (grid.col-sizes.at(i), grid.row-sizes.at(j))
          cetz.draw.rect((x - w/2, y - h/2), (x + w/2, y + h/2), stroke: tint.transparentize(80%) + 0.5pt)
        }
      }
    }
  })

}

/// A row/column specifier can be
/// - `auto`, meaning all row/columns are automatically sized
/// - a number or length, specifying the size
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


// Place a node with a uv position in a flexigrid
// taking into account node alignment within cells
#let get-node-origin(node, grid) = {
  let cell = utils.interp-grid-cell(grid, node.pos)
  let (w, h) = node.size
  let (x-shift, y-shift) = (0, 0)

  if node.align.x == left   { x-shift = -cell.w/2 + w/2 }
  if node.align.x == right  { x-shift = +cell.w/2 - w/2 }
  if node.align.y == bottom { y-shift = -cell.h/2 + h/2 }
  if node.align.y == top    { y-shift = +cell.h/2 - h/2 }

  return (cell.x + x-shift, cell.y + y-shift)
}

#let place-node-in-grid(node, grid) = {
  if node.enclose != none {
    // enclose node
    let points = node.enclose.map(uv => {
     let (x, y, w, h) = utils.interp-grid-cell(grid, uv)
     (
      (x - w/2, y - h/2, 0.),
      (x - w/2, y + h/2, 0.),
      (x + w/2, y - h/2, 0.),
      (x + w/2, y + h/2, 0.),
     )
    }).join()
    
    let (low, high) = cetz.process.aabb.aabb(points)

    node.pos = cetz.vector.scale(cetz.vector.add(low, high), 0.5)
    node.size = cetz.vector.sub(high, low).slice(0, 2)
  } else {
    assert.ne(node.pos, auto)
    node.pos = get-node-origin(node, grid)
  }
  node
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
  ..args,
  gutter: 1,
  origin: (0,0),
  columns: auto,
  rows: auto,
  name: none,
  debug: false,
) = {
  let col-spec = interpret-rowcol-spec(columns)
  let row-spec = interpret-rowcol-spec(rows)

  objects = utils.as-array(objects) + args.pos().join()
  gutter = utils.as-pair(gutter)

  cetz.draw.get-ctx(ctx => {

    let gutter = gutter.map(g => cetz.util.resolve-number(ctx, g))
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
    let grid = cell-sizes-from-rects(nodes, gutter)
    grid.col-sizes = apply-rowcol-spec(ctx, col-spec, grid.col-sizes)
    grid.row-sizes = apply-rowcol-spec(ctx, row-spec, grid.row-sizes)
    grid += cell-centers-from-sizes(grid)

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

    // let (_, ..node-coords) = cetz.coordinate.resolve(
    //   with-coordinate-resolver(ctx, uv-resolver),
    //   ..nodes.map(n => utils.interpret-as-uv(n.pos)),
    // )

    nodes = nodes.map(node => place-node-in-grid(node, grid))

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

    // draw help lines and flexigrid cells
    draw-flexigrid(grid, debug: debug)
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
