#import "utils.typ"
#import "deps.typ": cetz
#import "nodes.typ" as Nodes
#import "edges.typ"
#import "debug.typ": debug-level


#let cell-sizes-from-nodes(nodes) = {
  let (u-min, u-max) = (float.inf, -float.inf)
  let (v-min, v-max) = (float.inf, -float.inf)

  for node in nodes {
    let (u, v) = node.pos
    if u < u-min { u-min = u }
    if u-max < u { u-max = u }
    if v < v-min { v-min = v }
    if v-max < v { v-max = v }
  }

  (u-min, u-max) = (calc.floor(u-min), calc.ceil(u-max))
  (v-min, v-max) = (calc.floor(v-min), calc.ceil(v-max))

  let (n-cols, n-rows) = (u-max - u-min + 1, v-max - v-min + 1)
  let (col-sizes, row-sizes) = ((0,)*n-cols, (0,)*n-rows)

  for node in nodes {
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


#let interp-grid-point(grid, (u, v)) = {
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  (
    utils.interp(grid.col-centers, i),
    utils.interp(grid.row-centers, j),
  )
}

#let interp-grid-cell(grid, (u, v)) = {
  let (i, j) = (u - grid.u-min, v - grid.v-min)
  (
    x: utils.interp(grid.col-centers, i),
    y: utils.interp(grid.row-centers, j),
    w: utils.interp(grid.col-sizes, i),
    h: utils.interp(grid.row-sizes, j),
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
        let h = grid.row-sizes.at(j)
        cetz.draw.line((0, y - h/2), (0, y + h/2), stroke: (thickness: 1pt))
      }
    }

    if draw-cells {
      for (i, x) in grid.col-centers.enumerate() {
        for (j, y) in grid.row-centers.enumerate() {
          let (w, h) = (grid.col-sizes.at(i), grid.row-sizes.at(j))
          cetz.draw.circle((x, y), radius: 0.8pt, fill: red, stroke: none)
          cetz.draw.rect((x - w/2, y - h/2), (x + w/2, y + h/2), stroke: red.transparentize(85%))
        }
      }
    }
  })

}

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
  gutter: 0,
  debug: false,
  origin: (0,0),
  columns: auto,
  rows: auto,
  name: none,
) = {
  let col-spec = interpret-rowcol-spec(columns)
  let row-spec = interpret-rowcol-spec(rows)

  objects = utils.as-array(objects)


  let scene = cetz.draw.get-ctx(ctx => {
    let gutter = cetz.util.resolve-number(ctx, gutter)
    let (_, origin) = cetz.coordinate.resolve(ctx, origin)
    cetz.draw.translate(origin)


    let (elements,) = cetz.process.many(ctx, objects)

    // get elements that are fletcher objects
    let nodes = elements.filter(element => {
      "fletcher" in element and element.fletcher.class == "node"
    }).map(element => element.fletcher)

    // compute the cell sizes and positions in flexigrid
    let grid = cell-sizes-from-nodes(nodes)
    grid.col-sizes = apply-rowcol-spec(ctx, col-spec, grid.col-sizes)
    grid.row-sizes = apply-rowcol-spec(ctx, row-spec, grid.row-sizes)
    grid += cell-centers-from-sizes(grid, gutter: gutter)

    // draw things

    if debug-level(debug, "grid") {
      cetz.draw.group(draw-flexigrid(grid, debug: debug))
    }

    for (object, element) in objects.zip(elements) {
      if "fletcher" in element {
        let node = element.fletcher
        let cell = interp-grid-cell(grid, node.pos)
        Nodes.draw-node-in-cell(node, cell)
      } else {
        (object,)
      }
    }

  })

  cetz.draw.group({
    cetz.draw.set-ctx(ctx => {
      ctx.fletcher-debug = debug
      return ctx
    })
    scene
  }, name: name)
}

#let diagram(..args) = cetz.canvas(flexigrid(..args))
