#import "shapes.typ"
#import "utils.typ"
#import "deps.typ": cetz
#import "debug.typ": debug-level, debug-draw

#let BASE_NODE_STYLE = (
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
        base: BASE_NODE_STYLE,
        merge: (node: node.style),
        root: "node",
      ).node

      // resolve extrusion lengths or multiples of stroke thickness to cetz numbers
      let thickness = cetz.util.resolve-number(ctx, utils.get-thickness(style.stroke))
      let extrude = style.extrude.map(e => {
        if type(e) == length { return cetz.util.resolve-number(ctx, e) }
        if type(e) in (int, float) { return e*thickness }
      })

      let node = node
      // node.size = node.size.map(a => a + cetz.util.resolve-number(ctx, 2*style.inset))

      for (i, extrude) in extrude.enumerate() {
        cetz.draw.group({
          cetz.draw.set-style(..style, fill: if i == 0 { style.fill })
          (node.shape)(node, extrude)
        })
      }
    })

    debug-draw(debug, "node", {
      cetz.draw.circle((0,0), radius: 0.8pt, fill: red, stroke: none)
      let (w, h) = node.size
      cetz.draw.rect((-w/2,-h/2), (+w/2,+h/2), stroke: red + 0.25pt)
    })
  }, name: node.name)

  (ctx => {
    let group = group-callback(ctx)
    let calc-anchors = if "node" in (group.anchors)(()) {
      // defer all anchors to the node named "node" within the group
      k => (group.anchors)(("node", ..k))
    } else {
      k => (group.anchors)(k)
    }
    return group + (anchors: calc-anchors)
  },)

}


#let node(
  pos,
  ..args,
  shape: shapes.rect,
  name: none,
  align: center + horizon,
  weight: 1,
  debug: auto,
) = {

  // // apply inset
  // body = utils.switch-type(inset,
  //   length: inset => pad(inset, body),
  //   dictionary: args => pad(..args, body),
  // )
  // 
  if args.pos().len() > 1 { utils.error("invalid positional argument in node: #0", args.pos().slice(1)) }
  let body = args.pos().at(0, default: none)

  let style = args.named()

  if body == none {
    if style.at("inset", default: auto) == auto { style.inset = 0 }
  } else {
    body = text([#body], top-edge: "cap-height", bottom-edge: "baseline")
  }



  (ctx => {

    let style = cetz.styles.resolve(
      ctx.style,
      base: BASE_NODE_STYLE,
      merge: (node: style),
      root: "node",
    ).node

    let (w, h) = cetz.util.measure(ctx, body)
    let inset = cetz.util.resolve-number(ctx, style.inset)
    w += 2*inset
    h += 2*inset

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
      debug: debug,
    )

    let (obj,) = draw-node-at(node-data, pos)
    
    obj(ctx) + (fletcher: node-data)
  },)
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