#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-group


/* Flexilines and flexigrids */

// A _flexiline_ is a coordinate system on a 1d line, consisting of an array of _cells_,
// where each cell has a physical size/length. The center of each cell is determined by
// their sizes and a required _spacing_ or gutter between adjacent cells.
// 
// The flexiline defines a coordinate mapping from $u$ (the cell index) to $x$ (the cell's
// physical center coordinate), with a linear interpolation behaviour for fractional $u$.
// 
// A _rod_ is a region spanning between two coordinates `lo` and `hi` on a flexiline which
// has an minimum size/length. A rod represents some content to be placed in a flexiline
// at a single coordinate $u$ (in which case `lo` and `hi` are the same) or spanning more
// than one cell (`lo < hi`).
// 
// To _resolve_ a flexiline is to choose cell sizes so that the rods
// "fit" into the cells as appropriate. E.g., a wide rod at $u = 1$ forces the cell at
// index $1$ to be at least that wide; and a rod with a span of two straddles between
// two cells, only forcing them to be wider if the rod is wider than the two cells'
// combined size plus the spacing between them. Rods can also have fractional coordinates,
// in which case the correct behaviour is less clear - but the resolved flexiline layout
// (including the center and size of each cell, but not the number of cells) should always
// be a continuous function of the rods' centers, sizes and spans.
// 
// A _flexigrid_ is the 2d analogue of a flexiline, consisting of a pair of independent
// flexilines whose cartesian product define a 2d grid layout with rectangular cells.
// A _rect_ is the 2d analogue of a _rod_, represented as a pair or cartesian product
// of two rods. Rects have a 2d center, width and height, and colspan and rowspan.
// 
// To resolve a flexigrid, we consider each axis in turn and resolve the horizontal and
// vertical flexiline independently. Resolving a flexiline is done with a simple iterative
// algorithm: put rods on the flexiline, and measure how much larger the cells should be,
// and update the cell and rod positions, and repeat until converged.


/* rods and flexilines */

#let rod-bounds(rods) = {
  let lo = +calc.inf
  let hi = -calc.inf
  for rod in rods {
    if rod.lo < lo { lo = rod.lo }
    if rod.hi > hi { hi = rod.hi }
  }
  if float.is-infinite(lo) { lo = 0. }
  if float.is-infinite(hi) { hi = 0. }
  lo = calc.floor(lo)
  hi = calc.ceil(hi)
  return (lo, hi)
}

#let centers-from-sizes(sizes, spacing, flip, init: 0) = {
  let centers = ()
  let x = init
  for (i, size) in sizes.enumerate() {
    if i > 0 { x += spacing }
    x += size/2
    centers.push(x)
    x += size/2
  }
  let x-max = x
  if flip {
    centers = centers.map(x => x-max - x)
  }
  return centers
}


#let get-interpolated-flexiline-cell(fl, lo, hi) = {
  let (left-i, right-i) = (lo - fl.min, hi - fl.min)
  if fl.flip {
    (left-i, right-i) = (right-i, left-i)
  }
  let left-center = utils.interp(fl.centers, left-i, spacing: fl.spacing)
  let left-size = utils.interp(fl.sizes, left-i)

  let right-center = utils.interp(fl.centers, right-i, spacing: fl.spacing)
  let right-size = utils.interp(fl.sizes, right-i)

  let x-left = left-center - left-size/2
  let x-right = right-center + right-size/2

  (
    center: (x-left + x-right)/2,
    size: x-right - x-left,
  )
}


#let resolve-flexiline(rods, spacing, flip, max-iters: 100) = {
  let (u-min, u-max) = rod-bounds(rods)
  // extending the bounds means first and last cells are always size zero
  // which makes correct extrapolation of coords beyond bounds correct
  u-min -= 1
  u-max += 1
  let n-cells = u-max - u-min + 1

  let sizes = (0.,)*n-cells
  let centers = centers-from-sizes(sizes, spacing, flip, init: -spacing)
  let fl = (
    centers: centers,
    sizes: sizes,
    min: u-min,
    flip: flip,
    spacing: spacing,
  )

  let iteration = 0
  while iteration < max-iters {
    let sizes = (0.,)*n-cells

    for rod in rods {
      let (lo, hi) = rod
      if flip { (lo, hi) = (hi, lo) }
      let i-left = calc.floor(lo) - u-min
      let i-right = calc.ceil(hi) - u-min

      let cell = get-interpolated-flexiline-cell(fl, rod.lo, rod.hi)
      let left-rod-edge = cell.center - rod.size/2
      let right-rod-edge = cell.center + rod.size/2
      
      let left-cell-center = fl.centers.at(i-left)
      let right-cell-center = fl.centers.at(i-right)

      let left-cell-width = 2*(left-cell-center - left-rod-edge)
      let right-cell-width = 2*(right-rod-edge - right-cell-center)

      sizes.at(i-left) = calc.max(sizes.at(i-left), left-cell-width)
      sizes.at(i-right) = calc.max(sizes.at(i-right), right-cell-width)

      assert(sizes.all(s => s >= 0))
    }

    let deviation = calc.max(..cetz.vector.sub(fl.sizes, sizes).map(calc.abs))
    if deviation < 1e-4 { break }

    // TODO: figure out an effective 'scheduler'
    let t = (0.5, 0.9, 1).at(calc.rem(iteration, 3))

    fl.sizes = cetz.vector.lerp(fl.sizes, sizes, t)
    fl.centers = centers-from-sizes(fl.sizes, spacing, flip, init: -spacing)

    iteration += 1
  }

  return (fl, iteration)
}

#let flexiline-bounds(fl) = {
  let c-left = fl.centers.first()
  let c-right = fl.centers.last()
  let s-left = fl.sizes.first()
  let s-right = fl.sizes.last()
  if fl.flip {
    (c-left, c-right) = (c-right, c-left)
    (s-left, s-right) = (s-right, s-left)
  }
  (c-left - s-left/2, c-right + s-right/2)
}

/* nodes and flexigrids */

#let node-to-rod(node, axis, flip) = {
  let span = node.cellspan.at(axis)
  if span == none {
    span = 0
  } else {
    span -= span.signum()
  }

  if axis == 1 {
    // rowspans should always stretch down the page
    span *= -1
  }

  let pos = node.uv-pos.at(axis)
  let lo = pos
  let hi = pos
  if flip {
    lo -= span
  } else {
    hi += span
  }

  (lo, hi) = (lo, hi).sorted()
  let rod = (
    lo: lo,
    hi: hi,
    size: node.bounding-size.at(axis),
  )
  return rod
}

#let node-to-rods(node, flips) = {
  if flips.order { node.uv-pos = node.uv-pos.rev() }
  let x-rod = node-to-rod(node, 0, flips.u)
  let y-rod = node-to-rod(node, 1, flips.v)
  return (x-rod, y-rod)
}

#let resolve-flexigrid(nodes, spacing, flips, max-iters: 20) = {
  let xy-rods = nodes.map(node => node-to-rods(node, flips))
  let (x-rods, y-rods) = (xy-rods.map(array.first), xy-rods.map(array.last))
  let (x-fl, x-iters) = resolve-flexiline(x-rods, spacing.first(), flips.u, max-iters: max-iters)
  let (y-fl, y-iters) = resolve-flexiline(y-rods, spacing.last(), flips.v, max-iters: max-iters)
  let flexigrid = (x: x-fl, y: y-fl, flips: flips)
  let iters = calc.max(x-iters, y-iters)
  return (flexigrid, iters)
}

/* placing nodes in flexigrids */

// nodes are placed inside a cell in a flexigrid.
// nodes with cellspans get their own cells which span the flexigrid.
// nodes at fractional coordinates are placed in cells which are linear interpolations
// of neighbouring flexigrid cells.
#let get-interpolated-flexigrid-cell(flexigrid, node) = {
  let ((lo: x-lo, hi: x-hi), (lo: y-lo, hi: y-hi)) = node-to-rods(node, flexigrid.flips)
  let x-span = get-interpolated-flexiline-cell(flexigrid.x, x-lo, x-hi)
  let y-span = get-interpolated-flexiline-cell(flexigrid.y, y-lo, y-hi)
  let (w, h) = node.bounding-size
  return (
    center: (x-span.center, y-span.center),
    size: (calc.max(x-span.size, w), calc.max(y-span.size, h)),
  )
}

// by default, setting the rowspan or colspan of a node
// causes it to fill its cell along that axis
#let grow-node-in-cell(node, cell) = {
  let (colspan, rowspan) = node.cellspan
  if colspan != none {
    node.bounding-size.first() = cell.size.first()
  }
  if rowspan != none {
    node.bounding-size.last() = cell.size.last()
  }
  return node
}

#let align-node-in-cell(node, cell) = {
  let (w, h) = node.bounding-size
  let (cw, ch) = cell.size

  let (x-shift, y-shift) = (0, 0)
  if node.align.x == left   { x-shift = -cw/2 + w/2 }
  if node.align.x == right  { x-shift = +cw/2 - w/2 }
  if node.align.y == bottom { y-shift = -ch/2 + h/2 }
  if node.align.y == top    { y-shift = +ch/2 - h/2 }

  node.pos = cetz.vector.add(cell.center, (x-shift, y-shift))
  return node
}

#let place-node-in-flexigrid(fg, node) = {
  let cell = get-interpolated-flexigrid-cell(fg, node)
  node.cell = cell // currently only used for debug drawing
  node = grow-node-in-cell(node, cell)
  node = align-node-in-cell(node, cell)
  return node
}

/* debug drawing */

#let trim-flexiline(fl) = {
  fl.centers = fl.centers.slice(1, -1)
  fl.sizes = fl.sizes.slice(1, -1)
  fl.min += 1
  return fl
}

#let draw-flexigrid(grid, info: none, debug: true) = {
  let draw-lines = debug-level(debug, "grid.lines")
  let draw-coords = debug-level(debug, "grid.coords")
  let draw-cells = debug-level(debug, "grid.cells")
  let draw-sizes = draw-lines

  let DEBUG_COLOR = red.transparentize(30%)
  let line-stroke-style = stroke(paint: DEBUG_COLOR, thickness: 0.5pt, dash: "dotted")
  let size-stroke-style = stroke(paint: DEBUG_COLOR, thickness: 1pt)
  let tickstyle(it) = text(0.8em, DEBUG_COLOR, raw(str(it)))

  grid.x = trim-flexiline(grid.x)
  grid.y = trim-flexiline(grid.y)

  let (x-min, x-max) = flexiline-bounds(grid.x)
  let (y-min, y-max) = flexiline-bounds(grid.y)
  
  debug-group({
    if draw-cells {
      let t = 0.5pt
      cetz.draw.stroke(DEBUG_COLOR)
      for i in range(grid.x.centers.len()) {
        for j in range(grid.y.centers.len()) {
          let (x, y) = (grid.x.centers.at(i), grid.y.centers.at(j))
          let (w, h) = (grid.x.sizes.at(i), grid.y.sizes.at(j))
          cetz.draw.rect(
            (rel: (+t/2, +t/2), to: (x - w/2, y - h/2)),
            (rel: (-t/2, -t/2), to: (x + w/2, y + h/2)),
            stroke: t,
          )
        }
      }
    }


    cetz.draw.group({
      cetz.draw.fill(DEBUG_COLOR)
      cetz.draw.stroke(none)
      cetz.draw.set-style(content: (padding: 0.25em))
      for (i, x) in grid.x.centers.enumerate() {
        if draw-coords {
          cetz.draw.content((x, y-min), tickstyle(i + grid.x.min), anchor: "north")
        }
        if draw-sizes {
          let w = grid.x.sizes.at(i)
          cetz.draw.rect((x - w/2, y-min), (to: (x + w/2, y-min), rel: (0, -size-stroke-style.thickness)), fill: size-stroke-style.paint)
        }
        if draw-lines {
          cetz.draw.line((x, y-min), (x, y-max), stroke: line-stroke-style)
        }
      }
      for (i, y) in grid.y.centers.enumerate() {
        if draw-coords {
          cetz.draw.content((x-min, y), tickstyle(i + grid.y.min), anchor: "east")
        }
        if draw-sizes {
          let h = grid.y.sizes.at(i)
          cetz.draw.rect((x-min, y - h/2), (to: (x-min, y + h/2), rel: (-size-stroke-style.thickness, 0)), fill: size-stroke-style.paint)
        }
        if draw-lines {
          cetz.draw.line((x-min, y), (x-max, y), stroke: line-stroke-style)
        }
      }
    })

  })
}

#let draw-xy-grid(flexigrid) = {
  let (x-min, x-max) = flexiline-bounds(trim-flexiline(flexigrid.x))
  let (y-min, y-max) = flexiline-bounds(trim-flexiline(flexigrid.y))
  let (x-floor, y-floor) = (calc.floor(x-min), calc.floor(y-min))
  let tickstyle(x) = text(0.8em, gray, raw(str(x)))
  debug-group({
    cetz.draw.set-style(content: (padding: 0.25em))
    cetz.draw.grid((x-floor, y-floor), (x-max, y-max), help-lines: true)
    for x in range(x-floor, calc.floor(x-max) + 1) {
      cetz.draw.content((x, y-floor), tickstyle(x), anchor: "north")
    }
    for y in range(y-floor, calc.floor(y-max) + 1) {
      cetz.draw.content((x-floor, y), tickstyle(y), anchor: "east")
    }
  })
}

/* interface */

#let uv-to-xy(fl, (u, v)) = {
  if fl.flips.order { (u, v) = (v, u) }
  let x = utils.interp(fl.x.centers, u - fl.x.min, spacing: fl.x.spacing)
  let y = utils.interp(fl.y.centers, v - fl.y.min, spacing: fl.y.spacing)
  return (x, y)
}

#let xy-to-uv(fl, (x, y, ..)) = {
  let u = utils.interp-inv(fl.x.centers, x, spacing: fl.x.spacing) + fl.x.min
  let v = utils.interp-inv(fl.y.centers, y, spacing: fl.y.spacing) + fl.y.min
  if fl.flips.order { (u, v) = (v, u) }
  return (u, v)
}

#let with-coord-resolver(ctx, resolver) = {
  if type(ctx.resolve-coordinate) == array {
    ctx.resolve-coordinate.push(resolver)
  } else {
    ctx.resolve-coordinate = (resolver,)
  }
  return ctx
}

#let nans = (float.nan, float.nan)

#let layout-coord-resolver(ctx, c) = {
  if type(c) == label { return nans }
  if type(c) == dictionary {
    if "uv" in c { return c.uv }
    if "xy" in c { return nans }
    if "name" in c {
      panic(c)
    }
  }
  return c
}

#let flexigrid-coord-resolver(fl, ctx, c) = {
  if type(c) == label { return str(c) }
  if type(c) == dictionary {
    if "uv" in c { return uv-to-xy(fl, c.uv) }
    if "xy" in c { return c.xy }
    if "rel" in c and type(c.rel) == dictionary and "uv" in c.rel {
      if c.remove("no-flip", default: false) {
        let (u, v) = c.rel.uv
        if fl.flips.u { u *= -1 }
        if fl.flips.v { v *= -1 }
        if fl.flips.order { (u, v) = (v, u) }
        c.rel.uv = (u, v)
      }
      // resolve relative expressions (rel: (uv: Δ), to: X)
      // by adding X + Δ in uv-space, not xy-space
      // let (_, prev-xy) = cetz.coordinate.resolve(ctx, c.at("to", default: ()))
      let prev-xy = ctx.prev.pt
      let prev-uv = xy-to-uv(fl, prev-xy)
      let new-uv = cetz.vector.add(prev-uv, c.rel.uv)
      return uv-to-xy(fl, new-uv)
    }
  }
  return c
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


/* argument parsing */


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
  return (u: u, v: v, order: flip)
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
  ..args,
  /// Gutter between cells.
  ///
  /// Numbers are interpreted in CeTZ units.
  /// Column and row gutter can be controlled independently as the first and last numbers
  /// in a pair, `(col-gutter, row-gutter)`.
  ///
  /// #let fig(s) = cetz.canvas({
  ///   fletcher.flexigrid(
  ///     debug: "grid",
  ///     spacing: s,
  ///     node((0,0), [Wide], fill: blue.mix(white)),
  ///     node((1,1), rotate(90deg, reflow: true)[Tall], fill: green.mix(white))
  ///   )
  /// })
  /// #frame-row(..(0, 5pt, (0.2, 0.8), 1).map(s => {
  ///   align(center + horizon)[#fig(s) \ #raw("spacing: " + repr(s))]
  /// }))
  /// -> number | length | pair
  spacing: 1.0,
  axes: (ltr, ttb),
  max-layout-iterations: 20,
  debug: false,
) = {
  if args.named().len() > 0 {
    utils.error("unknown named argument: #..0", args.named().keys())
  }
  let objects = args.pos().join()

  spacing = utils.as-pair(spacing)
  let axis-flips = interpret-axes(axes)


  cetz.draw.get-ctx(ctx => {

    let spacing = spacing.map(g => cetz.util.resolve-number(ctx, g))


    /* Layout pass */
    // During the layout pass, all fletcher nodes are extracted and measured
    // to determine the flexigrid cell sizes, but nothing is drawn.
    // Coordinates are resolved in a context where only $u v$ coordinates are
    // kept, and anything else returns `float.nan`.
    
    let layout-ctx = with-coord-resolver(ctx, layout-coord-resolver)
    layout-ctx.shared-state.fletcher = (
      pass: "layout",
      nodes: (),
    )
    let layout-pass = process-only-ctx(layout-ctx, objects)
    let nodes = layout-pass.shared-state.fletcher.nodes

    // nodes which are placed in the flexigrid with $u v$ coordinates
    let uv-nodes = nodes.filter(node => node.uv-pos != none)
    let (fg, iters) = resolve-flexigrid(uv-nodes, spacing, axis-flips, max-iters: max-layout-iterations)

 
    /* Node placement pass */
    // After the flexigrid is determined, process all nodes and place them in
    // flexigrid cells. This might involve resolving coordinates with anchors,
    // so it requires a proper pass. This happens _before_ processing edges.
    // Edges are processed separately because we want edges to be able to snap to
    // nodes defined later in a diagram, so edges must be considered after nodes.
    let placement-ctx = with-coord-resolver(ctx, flexigrid-coord-resolver.with(fg))
    placement-ctx.shared-state.fletcher = (
      pass: "placement",
      nodes: nodes,
      current-node: 0,
      place-node-in-flexigrid: place-node-in-flexigrid.with(fg),
    )
    let placement-pass = process-only-ctx(placement-ctx, objects)
    let nodes = placement-pass.shared-state.fletcher.nodes



    /* Final pass */
    // In this pass, everything is drawn and $u v$ coordinates are resolved with
    // respect to the now-determined flexigrid.

    // extra context used by objects
    (ctx => {
      ctx = with-coord-resolver(ctx, flexigrid-coord-resolver.with(fg))
      ctx.shared-state.fletcher = (
        pass: "final",
        nodes: nodes, // must contain FINAL node coords
        current-node: 0,
        debug: debug,
      ) 
      return (ctx: ctx)
    },)

    objects

    draw-flexigrid(fg, info: [Iterations: #iters], debug: debug)
    if debug-level(debug, "grid.xy") {
      draw-xy-grid(fg)
    }

    // remove flexigrid context
    (ctx => {
      ctx.shared-state.remove("fletcher")
      return (ctx: ctx)
    },)
  })
}