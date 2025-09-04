#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-group, get-debug
#import "shapes.typ"
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

      let style = cetz.styles.resolve(
        ctx.style,
        base: DEFAULT_NODE_STYLE,
        merge: (node: node.style),
        root: "node",
      ).node

      // resolve extrusion lengths or multiples of stroke thickness to cetz numbers
      let thickness = cetz.util.resolve-number(ctx, utils.get-thickness(style.stroke))
      let extrude = style.extrude.map(e => {
        if type(e) == length { return cetz.util.resolve-number(ctx, e) }
        if type(e) in (int, float) { return e*thickness }
      })

      for (i, extrude) in extrude.enumerate() {
        cetz.draw.set-style(..style, fill: if i == 0 { style.fill })
        (node.shape)(node, extrude)
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



#let _node(
  ..options,
  debug: auto,
) = {

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

  (ctx => {

    if "fletcher" not in ctx.shared-state {
      ctx.shared-state.fletcher = (
        pass: none,
        nodes: (),
        edges: (),
      )
    }
    let fletcher-ctx = ctx.shared-state.fletcher


    let style = cetz.styles.resolve(
      ctx.style,
      base: DEFAULT_NODE_STYLE,
      merge: (node: style),
      root: "node",
    ).node

    let (body, shape) = (body, shape)
    let (w, h) = (0, 0)
    if utils.is-cetz(body) {
      let (low, high) = cetz.process.many(ctx, body).bounds
      (w, h, ..) = cetz.vector.sub(high, low)
      shape = (node, extrude) => body
      body = none
    } else if body != none {
      body = text([#body], top-edge: "cap-height", bottom-edge: "baseline")
      (w, h) = cetz.util.measure(ctx, body)
      let inset = cetz.util.resolve-number(ctx, style.inset)
      w += 2*inset
      h += 2*inset
    }

    let node-data = (
      class: "node",
      pos: position,
      body: body,
      shape: shape,
      style: style,
      name: name,
      size: (w, h),
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
      node-data.pos = ((..v) => array.zip(..v.pos()).map(((a, b)) => (a + b)/v.pos().len()), ..node-data.enclose,)
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
/// Nodes are content which #link(<edges>)[edges] can snap to.
/// Nodes can have various shapes (rect, circle), styles (fill, stroke).
#let node(
  ..args,
  /// Content to draw in the node. -> content
  body: none,
  shape: shapes.rect,
  name: none,
  align: center + horizon,
  weight: 1,
  enclose: none,
  snap: true,
  debug: auto,
) = {
  // validate arguments
  let pos = args.pos()

  let options = (
    body: body,
    shape: shape,
    name: name,
    align: align,
    weight: weight,
    enclose: enclose,
    snap: snap,
  )

  options += parsing.interpret-node-positional-args(pos, options)

  if options.name != none { options.name = str(options.name) }

  options.style = args.named() // todo: validate

  _node(
    ..options,
    debug: debug,
  )

}

