#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-group

#import "shapes.typ"

// Calculate the appropriate sizes `w0` and `w1` of adjacent cells
// when placing a node of width `W` at position `0 <= t <= 1 ` with
// cell gutter `g`.
// https://jollywatt.github.io/flexigrid
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

// From an array of rectangles, each of the form
// `(pos: array, size: array, weight: number)`,
// calculate the sizes of flexigrid cells.
// 
// Rectangle positions can be fractional.
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


  // interpret enclose nodes as multiple rects
  rects = rects.map(rect => {
    if rect.enclose == none { return rect }

    let (u-min, u-max) = (float.inf, -float.inf)
    let (v-min, v-max) = (float.inf, -float.inf)
    for (u, v) in rect.enclose {
      if u < u-min { u-min = u }
      if u-max < u { u-max = u }
      if v < v-min { v-min = v }
      if v-max < v { v-max = v }
    }

    rect.pos = (u-min, v-min)
    rect.cellspan = (u-max - u-min + 1, v-max - v-min + 1)
    // panic(rect)
    return rect
  })

  // interpret rects with colspan/rowspan as multiple rects
  // whose total sizes (plus gutter) is the original size
  // this is the only step that is sensitive to the order of rects
  rects = rects.map(rect => {
    let (colspan, rowspan) = rect.cellspan
    if colspan == none and rowspan == none { return rect }
    let (u, v) = rect.pos
    let (w, h) = rect.size
    if colspan != none {
      range(colspan).map(i => (
        ..rect,
        pos: (u + i, v),
        size: ((w - col-gutter*(colspan - 1))/colspan, h)
      ))
    }
    if rowspan != none {
      range(rowspan).map(j => (
        ..rect,
        pos: (u, v + j),
        size: (w, (h - row-gutter*(rowspan - 1))/rowspan)
      ))
    }
  }).flatten()

  // enlarge cells to fit rects
  // handling fractional rect positions nicely
  for rect in rects {
    let (w, h) = rect.size
    let (u, v) = rect.pos

    let (i, j) = (u - u-min, v - v-min)
    let (i-floor, j-floor) = (calc.floor(i), calc.floor(j))
    let (i-fract, j-fract) = (calc.fract(i), calc.fract(j))

    let (w0, w1) = (col-sizes.at(i-floor), col-sizes.at(i-floor + 1))
    let (w0new, w1new) = cell-sizer(w, w0, w1, i-fract, col-gutter)
    col-sizes.at(i-floor) =  utils.lerp(w0, calc.max(w0, w0new), rect.weight)
    col-sizes.at(i-floor + 1) = utils.lerp(w1, calc.max(w1, w1new), rect.weight)

    let (h0, h1) = (row-sizes.at(j-floor), row-sizes.at(j-floor + 1))
    let (h0new, h1new) = cell-sizer(h, h0, h1, j-fract, row-gutter)
    row-sizes.at(j-floor) = utils.lerp(h0, calc.max(h0, h0new), rect.weight)
    row-sizes.at(j-floor + 1) = utils.lerp(h1, calc.max(h1, h1new), rect.weight)
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
        cetz.draw.on-layer(-1, cetz.draw.line((x, grid.y-min), (x, grid.y-max), stroke: (thickness: 0.5pt)))
      }
      if draw-coords {
        let coord = i + grid.u-min
        if grid.axis-flips.u { coord *= -1 }
        cetz.draw.content((x, grid.y-min), text(10pt, tint, raw(str(coord))), anchor: "north")
        let w = grid.col-sizes.at(i)
        cetz.draw.line((x - w/2, grid.y-min), (x + w/2, grid.y-min), stroke: (thickness: 1pt))
      }
    }
    for (j, y) in grid.row-centers.enumerate().slice(1,-1) {
      if draw-lines {
        cetz.draw.on-layer(-1, cetz.draw.line((grid.x-min, y), (grid.x-max, y), stroke: (thickness: 0.5pt)))
      }
      if draw-coords {
        let coord = j + grid.v-min
        if grid.axis-flips.v { coord *= -1 }
        cetz.draw.content((grid.x-min, y), text(10pt, tint, raw(str(coord))), anchor: "east")
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

// A row/column specifier can be
// - `auto`, meaning all row/columns are automatically sized
// - a number or length, specifying the size
// - an array of the above, specifying each row/column individually
// - a function taking the index and returning a size, `none` or `auto`
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

// Get cell details `(x, y, w, h)` from a flexigrid,
// respecting fractional coordinates and colspan/rowspan.
// Nodes in flexigrids are placed within these cells.
// Nodes can be aligned within their cell, can grow to the cell's
// size or shrink to the size of their label content / body.
#let get-flexigrid-cell(node, grid) = {
  if node.cellspan == (none, none) {
    return utils.interp-grid-cell(grid, node.pos)
  }

  let (x, y) = node.pos
  let (x1, y1) = (x, y)
  let (colspan, rowspan) = node.cellspan
  if colspan != none { x1 += colspan - 1 }
  if rowspan != none { y1 += rowspan - 1 }

  let lo = utils.interp-grid-cell(grid, (x, y))
  let hi = utils.interp-grid-cell(grid, (x1, y1))

  let (lox, hix) = (lo.x - lo.w/2, hi.x + hi.w/2)
  let (loy, hiy) = (lo.y - lo.h/2, hi.y + hi.h/2)

  return (
    x: (lox + hix)/2,
    y: (loy + hiy)/2,
    w: (hix - lox),
    h: (hiy - loy),
  )
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
    node.body-size = node.size
  } else {
    assert.ne(node.pos, auto)

    let cell = get-flexigrid-cell(node, grid)

    // a cellspan implies the node's width should fill the spanned columns
    // same for rowspan
    let (colspan, rowspan) = node.cellspan
    if colspan != none {
      node.body-size.at(0) = cell.w
      node.size.at(0) = cell.w
    }
    if rowspan != none {
      node.body-size.at(1) = cell.h
      node.size.at(1) = cell.h
    }
    
    let (w, h) = node.size
    let (x-shift, y-shift) = (0, 0)

    if node.align.x == left   { x-shift = -cell.w/2 + w/2 }
    if node.align.x == right  { x-shift = +cell.w/2 - w/2 }
    if node.align.y == bottom { y-shift = -cell.h/2 + h/2 }
    if node.align.y == top    { y-shift = +cell.h/2 - h/2 }

    node.pos = (cell.x + x-shift, cell.y + y-shift)
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

// mirrors cetz.process.many except discards
// everything but ctx, used for layout pass
#let process-only-ctx(ctx, objs) = {
  for obj in objs {
    let r = cetz.process.element(ctx, obj)
    if r != none { ctx = r.ctx }
  }
  return ctx
}

/// Interpret the @flexigrid.axes option.
///
/// Returns a dictionary with:
/// - `u`: Whether $u$ is reversed
/// - `v`: Whether $v$ is reversed
/// - `order`: Whether the axes are swapped to $(v, u)$
///
/// -> dictionary
#let interpret-axes(
  /// Pair of directions specifying the interpretation of $(u, v)$ coordinates.
  /// For example, `(ltr, ttb)` means $u$ goes $arrow.r$ and $v$ goes $arrow.b$.
  axes
) = {
	let dirs = axes.map(direction.axis)
	let flip
	if dirs == ("horizontal", "vertical") {
		flip = false
	} else if dirs == ("vertical", "horizontal") {
		flip = true
	} else {
		error("Axes #0 cannot both be in the same direction. Try `axes: (ltr, ttb)`.", axes)
	}
  let (u, v) = (rtl in axes, ttb in axes)
  // if flip { (u, v) = (v, u) }

  (
    u: u,
    v: v,
    order: flip,
  )
}


/// A "flexible" coordinate system to be placed in CeTZ canvas which adapts to nodes contained therein.
/// 
/// Objects drawn inside a `flexigrid` have access to a $u v$ coordinate system,
/// which is a nonlinear grid of rows and columns which stretch to fit nodes, like a table.
/// Only content placed in @node can affect the $u v$ grid; #[@edge]s and plain CeTZ objects in a flexigrid never affect the layout.
/// 
/// By default, nodes and edges use $u v$ coordinates while CeTZ objects use the default $x y$ coordinates.
/// Use the coordinate expressions `(uv: ..)` and `(xy: ..)` to specify the system.
/// Both systems can be mixed in coordinate expressions like `((uv: (1,2)), 50%, (xy: (0,0)))`.
/// 
/// ```example
/// #cetz.canvas({
///   import cetz.draw: *
///   fletcher.flexigrid(debug: "grid", {
///     set-style(node: (fill: yellow))
///     node((0,0))[Nodes...]
///     node((2,1))[...in $u v$ system]
///     circle((uv: (2,0)), radius: 5pt, fill: blue)
///     content((3,2))[Content in $x y$ system]
///   })
/// })
/// ```
/// 
/// The main @diagram function is essentially equivalent to @flexigrid wrapped in `cetz.canvas()`.
#let flexigrid(
  objects,
  ..args,
  /// Gutter between cells.
  /// 
  /// Numbers are interpreted in CeTZ units.
  /// Column and row gutter can be controlled independently as the first and last numbers in a pair, `(col-gutter, row-gutter)`.
  /// 
  /// #let fig(s) = cetz.canvas({
  ///   fletcher.flexigrid(
  ///     debug: "grid",
  ///     spacing: s,
  ///     node((0,0), [Wide], fill: blue.mix(white)),
  ///     node((1,1), rotate(90deg, reflow: true)[Tall], fill: green.mix(white))
  ///   )
  /// })
  /// #stack(dir: ltr, spacing: 1fr, ..(0, 5pt, (0.2, 0.8), 1).map(s => {
  ///   align(center + horizon)[#fig(s) \ #raw("spacing: " + repr(s))]
  /// }))
  /// -> number | length | pair
  spacing: 1,
  origin: (0,0),
  axes: (ltr, btt),
  columns: auto,
  rows: auto,
  name: none,
  /// Show debug annotations
  /// #DEBUG_LEVELS.keys().filter(x => x.starts-with("grid")).join("")
  /// -> bool | number | string | array
  debug: false,
) = {
  let col-spec = interpret-rowcol-spec(columns)
  let row-spec = interpret-rowcol-spec(rows)

  objects = utils.as-array(objects) + args.pos().join()
  spacing = utils.as-pair(spacing)

  if args.named().len() > 0 {
    utils.error("unknown named argument: #..0", args.named().keys())
  }

  cetz.draw.get-ctx(ctx => {

    let gutter = spacing.map(g => cetz.util.resolve-number(ctx, g))
    let (_, origin) = cetz.coordinate.resolve(ctx, origin)
    // cetz.draw.translate(origin) // todo

    ctx.shared-state.fletcher = (
      pass: "layout",
      nodes: (),
      edges: (),
      current: (node: 0, edge: 0, uv: (0,0)), // index of current object
    )
    let node-styles = cetz.styles.resolve(
      shapes.DEFAULT_NODE_STYLE + shapes.NODE_SHAPES,
      merge: ctx.style.at("node", default: (:)),
    )
    ctx.style.node = node-styles

    // for the layout pass, we resolve uv coords by treating them as xy
    let layout-pass-ctx = with-coordinate-resolver(ctx, (ctx, c) => {
      if type(c) == dictionary {
        if "uv" in c { return c.uv }
        if "xy" in c { return c.xy }
      }
      if type(c) == label { return str(c) }
      return c
    })

    // run layout pass to retrieve fletcher objects
    let layout-pass = process-only-ctx(layout-pass-ctx, objects)
    let (nodes, edges) = layout-pass.shared-state.fletcher

    let axis-flips = interpret-axes(axes)
    nodes = nodes.map(node => {
      if axis-flips.order { node.pos = node.pos.rev() }
      if axis-flips.u { node.pos.at(0) *= -1 }
      if axis-flips.v { node.pos.at(1) *= -1 }
      node
    })

    // compute grid cell sizes and positions
    let grid = cell-sizes-from-rects(nodes, gutter)
    grid.col-sizes = apply-rowcol-spec(ctx, col-spec, grid.col-sizes)
    grid.row-sizes = apply-rowcol-spec(ctx, row-spec, grid.row-sizes)
    grid += cell-centers-from-sizes(grid)
    grid.axis-flips = axis-flips

    let uv-resolver(ctx, c) = {
      if type(c) == dictionary {
        if "uv" in c {
          if grid.axis-flips.order { c.uv = c.uv.rev() }
          if grid.axis-flips.u { c.uv.at(0) *= -1 }
          if grid.axis-flips.v { c.uv.at(1) *= -1 }
          return utils.uv-to-xy(grid, c.uv)
        }
        if "xy" in c { return c.xy }
        if "rel" in c and type(c.rel) == array and c.rel.all(x => type(x) in (int, float)) {
          let (_, prev-xy) = cetz.coordinate.resolve(ctx, c.at("to", default: ()))
          let prev-uv = utils.xy-to-uv(grid, prev-xy)
          let new-uv = cetz.vector.add(prev-uv, c.rel)
          return utils.uv-to-xy(grid, new-uv)
        }
      }
      if type(c) == label { return str(c) }
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
        current: (node: 0, edge: 0, uv: (0, 0)),
        flexigrid: grid,
        debug: debug,
      )
      ctx.style.node = node-styles
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
