#import "shapes.typ"
#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-draw, get-debug

#import "flexigrid.typ"

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

  debug-draw(debug, "node", {
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


#let _node(
  pos,
  body: none,
  style: (:),
  shape: shapes.rect,
  name: none,
  align: center + horizon,
  weight: 1,
  snap: true,
  debug: auto,
) = {

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

    let debug = get-debug(ctx, debug)

    let node-data = (
      class: "node",
      pos: pos,
      body: body,
      shape: shape,
      style: style,
      name: name,
      size: (w, h),
      align: align,
      weight: weight,
      snap: snap,
      debug: debug,
    )

    if fletcher-ctx.pass == "final" {
      node-data.pos = flexigrid.interpolate-grid-point(fletcher-ctx.flexigrid, node-data.pos)
    }
    

    if "current" in fletcher-ctx {
      ctx.shared-state.fletcher.current.node += 1
    }
    if fletcher-ctx.pass != "final" {
      ctx.shared-state.fletcher.nodes.push(node-data)
    }

    cetz.process.many(ctx, {
      draw-node-at(node-data, node-data.pos, debug: debug)
    })
  },)
}

#let node(
  position,
  ..args,
  shape: shapes.rect,
  name: none,
  align: center + horizon,
  weight: 1,
  snap: true,
  debug: auto,
) = {
  // validate arguments

  if args.pos().len() > 1 { utils.error("invalid positional argument in node: #0", args.pos().slice(1)) }
  let body = args.pos().at(0, default: none)

  let style = args.named() // todo: validate

  _node(
    position,
    body: body,
    style: style,
    shape: shape,
    align: align,
    weight: weight,
    snap: snap,
    name: name,
    debug: debug,
  )

}



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