#import "shapes.typ"
#import "utils.typ"
#import "deps.typ": cetz

#let BASE_NODE_STYLE = (
  stroke: none,
  fill: none,
  inset: 5pt,
  outset: 0pt,
  extrude: (0,),
)

#let draw-node-at(node, origin) = {
  cetz.draw.group({
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
      node.size = node.size.map(a => a + cetz.util.resolve-number(ctx, 2*style.inset))

      for (i, extrude) in extrude.enumerate() {
        cetz.draw.set-style(..style, fill: if i == 0 { style.fill })
        (node.shape)(node, extrude)
      }
    })
  }, name: node.name)

  // (ctx => {
  //   let group = group-callback(ctx)
  //   let calc-anchors = if "node" in (group.anchors)(()) {
  //     // defer all anchors to the node named "node" within the group
  //     k => (group.anchors)(("node", ..k))
  //   } else {
  //     k => (group.anchors)(k)
  //   }
  //   return group + (anchors: calc-anchors)
  // },)

}


#let node(
  pos,
  body,
  shape: shapes.rect,
  ..style,
  name: none,
  align: center + horizon,
  weight: 1,
) = {

  // // apply inset
  // body = utils.switch-type(inset,
  //   length: inset => pad(inset, body),
  //   dictionary: args => pad(..args, body),
  // )

  body = text(body, top-edge: "cap-height", bottom-edge: "baseline")

  (ctx => {

    let (w, h) = cetz.util.measure(ctx, body)

    let node-data = (
      class: "node",
      pos: pos,
      body: body,
      shape: shape,
      style: style.named(),
      name: name,
      size: (w, h),
      weight: weight,
      align: align
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