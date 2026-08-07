#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-group, debug-level, get-debug, DEBUG_STYLES
#import "shapes.typ": DEFAULT_NODE_STYLE, NODE_SHAPES
#import "parsing.typ"


#let draw-node-at(node, origin, debug: false) = {
  (ctx => {
    let objs = {
      cetz.draw.translate(origin)
      let style = node.style

      style.fit = style.fit*(1 - style.fit-cell)

      for (i, extrude) in node.style.extrude.enumerate() {
        cetz.draw.set-style(..style, fill: if i == 0 { style.fill })
        (node.draw)((
          body: if i == 0 { node.body },
          size: node.bounding-size,
          style: style,
          unit-length: ctx.length,
          extrude: extrude,
          body-center: node.body-center
        ))
      }
    }

    if node.layer != 0 { objs = cetz.draw.on-layer(node.layer, objs) }
    let group = cetz.draw.group(objs, name: node.name)
    group = group.first()(ctx)

    // override anchor behaviour for nodes
    let calc-anchors = if "node" in (group.anchors)(()) {
      // defer all anchors to the node named "node" within the group
      k => (group.anchors)(("node", k).flatten())
    } else {
      k => (group.anchors)(k)
    }
    return group + (anchors: calc-anchors)
  },)


  debug-group(layer: 10, {
    if node.cell != none and debug-level(debug, "node.cell") {
      let (center, size) = node.cell
      let lo = cetz.vector.sub(center, cetz.vector.scale(size, 0.5))
      let hi = cetz.vector.add(center, cetz.vector.scale(size, 0.5))
      cetz.draw.rect(lo, hi, ..DEBUG_STYLES.node.cell)
    }

    if debug-level(debug, "node.body") {
      let c = cetz.vector.add(node.pos, node.body-center)
      let s = cetz.vector.scale(node.body-size, 0.5)
      let lo = cetz.vector.sub(c, s)
      let hi = cetz.vector.add(c, s)
      cetz.draw.rect(lo, hi, ..DEBUG_STYLES.node.body)
    }

    if debug-level(debug, "node.outset") {
      let n = node
      n.style.extrude = (node.style.outset,)
      n.style.fill = none
      n.name = none
      n.body = none
      n.style.stroke = DEBUG_STYLES.node.outset.stroke
      cetz.draw.group(draw-node-at(n, n.pos, debug: false))
    }

    cetz.draw.translate(origin)
    if debug-level(debug, "node.origin") {
      cetz.draw.circle((0, 0), radius: 0.8pt, fill: red, stroke: none)
    }
    if debug-level(debug, "node.bounds") {
      let (w, h) = node.bounding-size
      cetz.draw.rect((-w/2,-h/2), (+w/2,+h/2), ..DEBUG_STYLES.node.bounds)
    }

  })

}


#let resolve-node-shape(ctx, node-styles, node) = {
  let shape = node.shape

  // a node shape is a dictionary with a `draw` entry
  let all-shapes = NODE_SHAPES
  // other shapes can be specified via
  // set-style(node: ((shape-name): (..)))
  for (k, v) in node-styles {
    if type(v) == dictionary and "draw" in v {
      all-shapes.insert(k, v)
    }
  }

  // be forgiving
  let aliases(it) = {
    if it in (std.circle, cetz.draw.circle) { return "circle" }
    if it == std.ellipse { return "ellipse" }
    if it in (std.rect, cetz.draw.rect) { return "rect" }
    if it == none { return "none" }
    return it
  }
  shape = aliases(shape)

  // use default shape unless node has styles for that shape
  let default-shape = node-styles.at("shape", default: auto)
  if default-shape != auto {
    default-shape = aliases(default-shape)
    let valid-args = {
      all-shapes.at(default-shape).keys()
      DEFAULT_NODE_STYLE.keys()
    }
    if node.style.keys().all(k => k in valid-args) {
      shape = default-shape
    }
  }

  if shape == auto {
    // deduce node shape from style options
    // given as named arguments to node(..)
    // e.g., `radius` implies circle
    for (name, (..options, draw)) in all-shapes {
      if node.style.keys().any(o => o in options) {
        shape = name
        break
      }
    }
  }

  if shape == auto {
    // if no shape is matched to node arguments
    // default shape can be given via set-style(node: (shape: ..))
    if "shape" in node-styles {
      shape = node-styles.shape
    }
  }

  if shape == auto {
    // just guess shape from node body
    if node.body == none { shape = "none"}
    else if node.enclose != none { shape = "rect" }
    else if node.cellspan != (none, none) { shape = "rect" }
    else {
      // choose based on body size and aspect ratio
      // this works best when nodes have no stroke, like in
      // commutative diagrams: single letters become circles
      // making edges connect more evenly
      let (w, h) = cetz.util.measure(ctx, [#node.body])
      if calc.max(w, h) > 2em.to-absolute()/ctx.length {
        shape = "rect"
      } else {
        // guess typical padding
        let inset = 0.5em.to-absolute()/ctx.length
        w += inset
        h += inset
        if calc.max(w/h, h/w) < 1.5 { shape = "circle" }
        else { shape = "rect" }
      }
    }
  }

  if shape not in all-shapes {
    utils.error("Unknown node shape #0. Try: #..1",
      repr(shape), all-shapes.keys())
  }

  // check no unknown style arguments are given for shape
  // (this is especially important for discoverability)
  let valid-args = {
    all-shapes.at(shape).keys()
    DEFAULT_NODE_STYLE.keys()
  }
  let invalid-args = node.style.keys().filter(arg => arg not in valid-args)
  if invalid-args.len() > 0 {
    utils.error(
      "Unknown node option #..invalid. Options for #shape nodes: #..valid",
      invalid: invalid-args,
      shape: shape,
      valid: valid-args,
    )
  }

  return shape
}

#let resolve-node-styles(ctx, node) = {

  // get style defaults (not yet with the node's specific styles)
  let node-styles = cetz.styles.resolve(
    DEFAULT_NODE_STYLE + NODE_SHAPES,
    merge: ctx.style.at("node", default: (:)),
  )

  node.shape = resolve-node-shape(ctx, node-styles, node)

  // resolve styles so that:
  // - node(prop: val) takes highest precedence
  // - set-style(node: (shape: (prop: val))) affects nodes of a given shape
  // - set-style(node: (prop: val)) affects all nodes not specified above
  // - set-style(prop: val) doesn't affect nodes at all
  let style = cetz.styles.resolve(
    node-styles,
    base: (
      (node.shape): DEFAULT_NODE_STYLE.keys()
        .map(k => (k, auto)).to-dict(),
    ),
    merge: ((node.shape): node.style),
  ).at(node.shape)

  if "draw" not in style {
    utils.error("node shape does not have a `draw` field; got `#0: #1`",
      node.shape, repr(style))
  }


  // resolve lengths to dimensionless numbers

  let thickness = cetz.util.resolve-number(ctx, utils.get-thickness(style.stroke))
  style.extrude = utils.one-or-array(style.extrude).map(e => {
    if type(e) == length { cetz.util.resolve-number(ctx, e) }
    else if type(e) in (int, float) { e*thickness }
  })

  style.outset = cetz.util.resolve-number(ctx, style.outset)


  node.style = style
  node.draw = style.draw
  return node
}


#let measure-node(ctx, style, body) = {

  // measure node label/body
  let body-size = {
    let (low, high) = cetz.process.many(ctx, body).bounds
    let (w, h, ..) = cetz.vector.sub(high, low)
    (w, h)
  }

  // account for how the shape fits within an enclosing flexigrid cell
  // if fit-cell is 1 then the whole node shape is enclosed in the cell
  // if fit-cell is 0 then the cell wraps around the node body (while the
  // node shape can bleed outside the cell bounds)
  style.fit *= style.fit-cell

  // measure size of node including its shape
  // and, for asymmetric shapes, determine the center of the node body
  // relative to the bounding center of the shape
  let bounding-size = body-size
  let body-center = (0., 0., 0.)

  let drawn = (style.draw)((
    size: body-size,
    body: body,
    extrude: 0,
    unit-length: ctx.length,
    style: style,
    body-center: body-center
  ))
  let (low, high) = cetz.process.many(ctx, drawn).bounds
  let (w, h, ..) = cetz.vector.sub(high, low)
  body-center = cetz.vector.scale(cetz.vector.add(high, low), -0.5)
  bounding-size = (w, h)

  return (body: body-size, bounding: bounding-size, body-center: body-center)
}


// ensure body is a cetz drawable and apply inset
#let resolve-node-body(ctx, body, inset, debug) = {
  if utils.is-cetz(body) { return body }

  if body == none {
    // empty nodes should still affect canvas bounds
    return cetz.draw.content((0,0), none)
  }

  let body = text([#body], top-edge: "cap-height", bottom-edge: "baseline")
  if debug-level(get-debug(ctx, debug), "node.inset") {
    body = rect(body, inset: 0pt, outset: 0pt, ..DEBUG_STYLES.node.inset)
  }

  // inset = 0
  return cetz.draw.content((0,0), [#body], padding: inset, name: "body")
}



#let _node(
  ..options,
  debug: auto,
) = {

  (ctx => {
    let (
      position,
      body,
      shape,
      style,
      align,
      name,
      weight,
      enclose,
      snap,
      layer,
      cellspan,
    ) = options.named()

    let data = (
      class: "node",
      pos: position,
      body: body,
      shape: shape,
      style: style,
      name: name,
      align: align,
      weight: weight,
      enclose: enclose,
      snap: snap,
      layer: layer,
      cellspan: cellspan,
      cell: none,
      debug: get-debug(ctx, debug),
    )

    /* Resolve styles */

    data = resolve-node-styles(ctx, data)
    data.body = resolve-node-body(ctx, data.body, data.style.inset, debug)
    let m = measure-node(ctx, data.style, data.body)
    data.body-size = m.body
    data.bounding-size = m.bounding
    data.body-center = m.body-center


    if "fletcher" not in ctx.shared-state {
      // node is not inside a flexigrid
      // but fletcher state is still needed for e.g., automatic edge-node snapping
      ctx.shared-state.fletcher = (
        pass: none,
        nodes: (),
      )
    }
    let fletcher-ctx = ctx.shared-state.fletcher

    if "current-node" in fletcher-ctx {
      ctx.shared-state.fletcher.current-node += 1
    }


    if fletcher-ctx.pass == "layout" {
      // In the layout pass, we only care about resolving
      // the uv coordinates of nodes and recording this in ctx.shared-state.

      // resolve uv coordinates
      let pos = utils.interpret-as-uv(data.pos)
      let uv
      (ctx, uv) = cetz.coordinate.resolve(ctx, pos)

      data.uv-pos = if not uv.any(float.is-nan) { uv.slice(0, 2) }
      ctx.shared-state.fletcher.nodes.push(data)

      // do not draw anything in layout pass
      // but do register dummy anchors so coordinates depending on this node don't panic
      return (ctx: ctx, name: data.name, anchors: _ => utils.nans)

    } else if fletcher-ctx.pass == "placement" {
      // In the node placement pass, node positions and sizes are resolved.
      // This happens after the flexigrid is determined but before edges are processed.

      let self = fletcher-ctx.nodes.at(fletcher-ctx.current-node)
      let original-pos = data.pos
      if self.uv-pos != none {
        // this is a uv node
        data = (fletcher-ctx.place-node-in-flexigrid)(self)

      } else {
        // this is an xy node
        // draw node at an exact coordinate
        let pos = utils.interpret-as-uv(data.pos)
        let xy
        (ctx, xy) = cetz.coordinate.resolve(ctx, pos)
        data.pos = xy

        if data.pos.any(float.is-nan) {
          utils.error("node coordinate #0 did not resolve (nodes cannot depend on edges)", original-pos)
        }
      }

      // pass data to state to be read in final pass
      ctx.shared-state.fletcher.nodes.at(fletcher-ctx.current-node) = data

      // since we need to resolve coordinates which might depend on anchors
      // continue and draw elements in the placement pass

    } else if fletcher-ctx.pass == "final" {
      // The node's position and size must be resolved by now (see placement pass).
      // Edges and nodes both read from `fletcher-ctx.nodes` as the source of truth
      // about nodes' final attributes.
      let self = fletcher-ctx.nodes.at(fletcher-ctx.current-node)
      data.pos = self.pos
      data.bounding-size = self.bounding-size
      data.cell = self.cell
      ctx.prev.pt = data.pos

    } else {
      // Node does not appear in a flexigrid.
      let xy
      (ctx, xy) = cetz.coordinate.resolve(ctx, data.pos)
      data.pos = xy
      ctx.shared-state.fletcher.nodes.push(data)

    }


    cetz.process.many(ctx, {
      draw-node-at(data, data.pos, debug: data.debug)
    })

  },)
}


/// Place a _node_ in a diagram or CeTZ canvas.
///
/// Nodes are content which #[@edge]s can snap to.
/// Nodes can have various shapes (rect, circle), styles (fill, stroke).
#let node(
  ..args,
  /// Content to draw in the node.
  ///
  /// This content is measured to automatically determine the size of the node.
  /// The @debug.node.body debug option shows the body's bounding box after @node.inset is applied.
  /// -> content
  body: none,
  /// The shape of the node's body enclosing its label.
  ///
  /// Built-in shapes are #fletcher.shapes.NODE_SHAPES.keys().map(it => raw(repr(it))).join(last: [ and ])[, ].
  ///
  /// Some node shapes accept other styling options which can be passed as arguments to @node.
  ///
  /// See also the @node-shapes section of the manual.
  /// -> auto | none | string
  shape: auto,

  /// Fill style of the node.
  ///
  /// The fill is drawn within the outline defined by the first @node.extrude value. For example:
  ///
  /// #example(```typ
  /// #diagram(
  ///   node-fill: yellow,
  ///   node-stroke: 1pt,
  ///   node((0,0), [A], extrude: (0, 3)),
  ///   node((1,0), [B], extrude: (3, 0)),
  /// )
  /// ```)
  fill: auto,
  /// Stroke style for the node outline.
  stroke: auto,
  /// Padding applied to the content in a node's body.
  ///
  /// The @debug.node.inset debug option draws a box around the
  /// body content before inset is applied.
  ///
  /// The inset can be a length like `5pt`, or a CeTZ-style array
  /// or dictionary: for example, `(0, 5pt)` for only horizontal
  /// padding; `(left: 5pt, rest: 10pt)` for per-edge padding.
  /// -> length | array | dictionary
  inset: auto,
  /// Separation between the node's visible outline and the
  /// snapping target for edges.
  ///
  /// This does not affect the node's appearance or layout, only how closely edges connect to it.
  ///
  /// When @debug.node.outset debug option is on, the node outset
  /// drawn as a green dotted line.
  ///
  /// #example(```typ
  /// #diagram(
  /// 	debug: "node.outset",
  /// 	node-stroke: 1pt,
  /// 	node((0,0), [Hello]),
  /// 	edge("<->"),
  ///   node((1,0), [World], outset: 5pt, shape: "ellipse"),
  /// )
  /// ```)
  ///
  /// See also @edge.outset, which controls how closely individual edges connect to nodes.
  ///
  /// -> length
  outset: auto,
  /// Draw strokes around the node at the given offsets to
  /// obtain a multi-stroke effect.
  /// Offsets can be numbers specifying multiples of the @node.stroke's thickness or lengths.
  ///
  /// The node's fill is drawn within the boundary defined by the first offset in
  /// the array.
  /// -> array
  extrude: auto,
  /// Canvas layer to draw node on.
  ///
  /// Nodes with equal layer are drawn in the order they are inserted.
  /// -> number
  layer: 0,
  /// Name of the node for use with coordinate anchors.
  ///
  /// This can also be passed as a positional argument (but then
  /// the name must be a label, not a string).
  /// -> label | str
  name: none,
  /// Align a node within its associated flexigrid cell.
  ///
  /// This only has effect when used inside a @diagram or @flexigrid.
  ///
  /// #frame-row(..(top + left, right).map(it => diagram(
  ///   debug: "node.cell",
  ///   spacing: 2pt,
  ///   node-fill: teal.lighten(50%),
  ///   node((0,0), align: it, raw(repr(it))),
  ///   node((0,1), width: 3cm, height: 5mm),
  ///   node((1,0), width: 5mm, height: 1cm),
  /// )))
  ///
  /// The node's associated cell is visible when the
  /// @debug.node.cell debug option is enabled.
  ///
  /// -> alignment
  align: center + horizon,
  /// How much the node influences the size of flexigrid rows/columns.
  ///
  /// If `0`, the node does not affect the flexigrid or other node positions.
  /// If `1`, rows and columns grow to fully accommodate the node.
  /// -> number
  weight: 1,
  enclose: none,
  /// Whether this node can have edges automatically snap to it.
  /// -> bool
  snap: true,

  /// The number of columns spanned by the node's @node-cells[flexigrid cell].
  ///
  /// The column span can be positive (meaning the cell grows rightwards)
  /// or negative (leftwards), or even fractional.
  /// The cell must span at least one column, so the range of this
  /// parameter is $(-oo, -1] union [1, oo)$.
  ///
  /// If the column span is not `none`, then node's width defaults
  /// to the full size of its enclosing cell.
  ///
  /// #example(```typ
  /// #diagram(
  ///   spacing: 5pt,
  ///   debug: "node.cell",
  ///   node((0,0), colspan: 3, $x y z$),
  ///   node((0,1), rowspan: 2, $x$),
  ///   node((1,1), $y$),
  ///   node((2,1), $z$),
  ///   node((2,2), colspan: -2, $y z$)
  /// )
  /// ```)
  ///
  /// See also @node.rowspan and @node.enclose.
  /// -> number | none
  colspan: none,
  /// Row span of the node's @node-cells[flexigrid cell].
  ///
  /// Analogous to @node.colspan.
  /// -> number
  rowspan: none,

  /// Whether to return a `metadata` object which can be placed inside equations,
  /// instead of returning an array of functions which can be inserted into a CeTZ canvas.
  ///
  /// If you often use fletcher in math mode, consider defining a shortcut:
  /// ```typ
  /// #let hom = edge.with(in-math: true)
  /// #let obj = node.with(in-math: true)
  /// ```
  /// Now, `hom` edges and `obj` nodes can be inserted into equations, like so:
  /// ```typ
  /// #diagram($x hom(|->) & obj(pi(x), stroke: #yellow)$)
  /// ```
  ///
  /// See also @edge.in-math.
  /// -> bool
  in-math: false,

  /// Enable debug annotations for only this node.
  /// See @debug.node.
  ///
  /// If `auto`, the debug setting is inherited from the enclosing @diagram or @flexigrid.
  debug: auto,
) = {

  let style = (
    fill: fill,
    stroke: stroke,
    inset: inset,
    outset: outset,
    extrude: extrude,
  ).pairs().filter(((k, v)) => v != auto).to-dict()
  style += args.named()

  let options = (
    body: body,
    shape: shape,
    name: name,
    align: align,
    weight: weight,
    enclose: enclose,
    snap: snap,
    style: style,
    layer: layer,
    cellspan: (colspan, rowspan),
    debug: debug,
  )

  let pos = args.pos()
  options += parsing.interpret-node-positional-args(pos, options)

  if options.name != none { options.name = str(options.name) }

  if in-math {
    options.body = math.equation(options.body)
    metadata((fletcher: "node", args: options))
  } else {
    _node(..options)
  }

}
