#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-group, get-debug
#import "shapes.typ": NODE_SHAPES
#import "parsing.typ"

#let DEFAULT_NODE_STYLE = (
  stroke: none,
  fill: none,
  inset: 5pt,
  outset: 0pt,
  extrude: (0,),
)


#let draw-node-at(node, origin, debug: false) = {
  
  let (group-callback,) = cetz.draw.group({
    cetz.draw.translate(origin)
    cetz.draw.get-ctx(ctx => { 

      let style = node.style

      // resolve extrusion lengths or multiples of stroke thickness to cetz numbers
      let thickness = cetz.util.resolve-number(ctx, utils.get-thickness(style.stroke))
      let extrude = style.extrude.map(e => {
        if type(e) == length { return cetz.util.resolve-number(ctx, e) }
        if type(e) in (int, float) { return e*thickness }
      })

      for (i, extrude) in extrude.enumerate() {
        cetz.draw.set-style(..style, fill: if i == 0 { style.fill })
        (node.draw)(node + (unit-length: ctx.length, extrude: extrude))
      }
    })

  }, name: node.name)

  // override anchor behaviour for nodes
  (ctx => {
    let group = group-callback(ctx)

    let calc-anchors = if "node" in (group.anchors)(()) {
      // defer all anchors to the node named "node" within the group
      k => (group.anchors)(("node", k).flatten())
    } else {
      k => (group.anchors)(k)
    }
    return group + (anchors: calc-anchors)
  },)

  if debug-level(debug, "node") {
    debug-group({
      cetz.draw.translate(origin)
      cetz.draw.circle((0,0), radius: 0.8pt, fill: red, stroke: none)
      let (w, h) = node.size
      if debug-level(debug, "node.stroke") {
        cetz.draw.rect((-w/2,-h/2), (+w/2,+h/2), stroke: red + 0.25pt)
      }
      if debug-level(debug, "node.outset") {
        let o = node.style.outset
        cetz.draw.rect(
          (rel: (-o, -o), to: (-w/2,-h/2)),
          (rel: (+o, +o), to: (+w/2,+h/2)),
          stroke: (paint: red, thickness: 0.25pt, dash: "densely-dotted"),
        )
      }
    })
  }

}


#let resolve-node-styles(ctx, style, shape, body) = {
  let ctx-style-node = ctx.style.at("node", default: (:))

  // a node shape is a dictionary with a `draw` entry
  let all-shapes = NODE_SHAPES // default shapes
  // other shapes can be specified via
  // set-style(node: ((shape-name): (..)))
  for (k, v) in ctx-style-node {
    if type(v) == dictionary and "draw" in v {
      all-shapes.insert(k, v)
    }
  }

  if shape == auto {
    // deduce node shape from style options
    // given as named arguments to node(..)
    // e.g., `radius` implies circle
    for (name, (..options, draw)) in all-shapes {
      if style.keys().any(o => o in options) {
        shape = name
        break
      }
    }
  }

  if shape == auto {
    // if no shape is matched to node arguments
    // default shape can be given via set-style(node: (shape: ..))
    if "shape" in ctx-style-node {
      shape = ctx-style-node.shape
    }
  }

  if shape == auto {
    // just guess shape from node body
    if body == none { shape = "none"}
    else {
      // choose based on body size and aspect ratio
      // this works best when nodes have no stroke, like in
      // commutative diagrams: single letters become circles
      // making edges connect more evenly
      let (w, h) = cetz.util.measure(ctx, [#body])
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

  // be forgiving
  if shape in (std.circle, cetz.draw.circle) { shape = "circle" }
  if shape in (std.rect, cetz.draw.rect) { shape = "rect" }
  if shape == none { shape = "none" }


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
  let invalid-args = style.keys().filter(arg => arg not in valid-args)
  if invalid-args.len() > 0 {
    utils.error(
      "Unknown node option #..invalid. Options for #shape nodes: #..valid",
      invalid: invalid-args,
      shape: shape,
      valid: valid-args,
    )
  }

  // resolve styles so that:
  // - node(prop: val) takes highest precedence
  // - set-style(node: (shape: (prop: val))) affects nodes of a given shape
  // - set-style(node: (prop: val)) affects all nodes not specified above
  // - set-style(prop: val) doesn't affect nodes at all
  let style = cetz.styles.resolve(
    ctx-style-node,
    base: (
      (shape): (      
        fill: auto,
        stroke: auto,
        inset: auto,
        outset: auto,
        extrude: auto,
      ),
    ),
    merge: ((shape): style),
  ).at(shape)

  if "draw" not in style {
    utils.error("node shape does not have a `draw` field; got `#0: #1`",
      shape, repr(style))
  }

  return style
}


#let measure-node(ctx, style, shape, body) = {

  if body == none {
    return (none, (0,0))
  }

  // measure node label/body
  let body-size = {
    let (low, high) = cetz.process.many(ctx, body).bounds
    let (w, h, ..) = cetz.vector.sub(high, low)
    (w, h)
  }

  // measure node shape
  let node-size = {
    if shape == none {
      shape = (node, extrude) => body
      body-size
    } else {
      let drawn = (style.draw)((
        size: body-size,
        body: body,
        extrude: 0,
        unit-length: ctx.length,
        style: style,
      ))
      let (low, high) = cetz.process.many(ctx, drawn).bounds
      let (w, h, ..) = cetz.vector.sub(high, low)
      (w, h)
    }
  }

  return (body, node-size)
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
    ) = options.named()

    if "fletcher" not in ctx.shared-state {
      ctx.shared-state.fletcher = (
        pass: none,
        nodes: (),
        edges: (),
      )
    }
    let fletcher-ctx = ctx.shared-state.fletcher

    let style = resolve-node-styles(ctx, style, shape, body)

    // ensure body is a cetz drawable
    if not utils.is-cetz(body) {
      if body == none {
        // empty nodes should still affect canvas bounds
        body = cetz.draw.content((0,0), none)
      } else {
        body = text([#body], top-edge: "cap-height", bottom-edge: "baseline")
        body = cetz.draw.content((0,0), [#body], padding: style.inset)
      }
    }

    let (body, size) = measure-node(ctx, style, shape, body)


    let node-data = (
      class: "node",
      pos: position,
      body: body,
      size: size,
      shape: shape,
      draw: style.draw,
      style: style,
      name: name,
      align: align,
      weight: weight,
      enclose: enclose,
      snap: snap,
      debug: get-debug(ctx, debug),
    )

    if node-data.pos == auto and node-data.enclose != none {
      // resolve enclose nodes without flexigrid
      // should still support engulfing other nodes
      // but not stuff requiring row/col knowledge
      // let spanning-points = node-data.enclose.map(fle)
      if node-data.enclose.len() == 1 {
        node-data.pos = node-data.enclose.first()
      } else {
        node-data.pos = ((..v) => array.zip(..v.pos()).map(((a, b)) => (a + b)/v.pos().len()), ..node-data.enclose,)
      }
    }

    if fletcher-ctx.pass == "final" {
      // node position was calculated by flexigrid
      // copy that position to actual node
      let self = fletcher-ctx.nodes.at(fletcher-ctx.current.node)
      node-data.pos = self.pos
      node-data.size = self.size
    } else {
      // resolve position
      let (ctx, origin) = cetz.coordinate.resolve(ctx, node-data.pos)
      node-data.pos = origin.slice(0, 2)
    }


    if "current" in fletcher-ctx {
      ctx.shared-state.fletcher.current.node += 1
    }
    if fletcher-ctx.pass != "final" {
      ctx.shared-state.fletcher.nodes.push(node-data)
    }

    cetz.process.many(ctx, {
      draw-node-at(node-data, node-data.pos, debug: node-data.debug)
    })
  },)
}


/// Place a _node_ in a diagram or CeTZ canvas.
/// 
/// Nodes are content which #[@edge]s can snap to.
/// Nodes can have various shapes (rect, circle), styles (fill, stroke).
#let node(
  ..args,
  /// Content to draw in the node. -> content
  body: none,
  shape: auto,

  /// Fill style of the node.
  ///  
  /// The fill is drawn within the outline defined by the first @node.extrude value.
  fill: auto,
  /// Stroke style for the node outline.
  stroke: auto,
  /// Padding between the node's content and its outline.
  inset: auto,
  /// Draw strokes around the node at the given offsets to
  /// obtain a multi-stroke effect.
  /// Offsets can be numbers specifying multiples of the @node.stroke's thickness or lengths.
  /// 
  /// The node's fill is drawn within the boundary defined by the first offset in
  /// the array.
  /// -> array
  extrude: auto,

  name: none,
  align: center + horizon,
  weight: 1,
  enclose: none,
  snap: true,
  debug: auto,
) = {

  let style = (
    fill: fill,
    stroke: stroke,
    inset: inset,
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
  )

  let pos = args.pos()
  options += parsing.interpret-node-positional-args(pos, options)

  if options.name != none { options.name = str(options.name) }

  _node(
    ..options,
    debug: debug,
  )

}

