#import "shapes.typ"
#import "utils.typ"

#let node(
  pos,
  body,
  shape: shapes.rect,
  inset: 0pt,
  outset: 0pt,
  name: none,
  align: center + horizon,
  weight: 1,
) = {

  // apply inset
  body = utils.switch-type(inset,
    length: inset => pad(inset, body),
    dictionary: args => pad(..args, body),
  )

  body = text(body, top-edge: "cap-height", bottom-edge: "baseline")

  ((
    class: "node",
    pos: pos,
    body: body,
    shape: shape,
    outset: outset,
    name: name,
    align: align,
    weight: weight,
  ),)
}

#let draw-node-in-cell(node, cell) = {
  import "deps.typ": cetz

  let (w, h) = node.size
  let (x-shift, y-shift) = (0, 0)

  if node.align.x == left   { x-shift = -cell.w/2 + w/2 }
  if node.align.x == right  { x-shift = +cell.w/2 - w/2 }
  if node.align.y == bottom { y-shift = -cell.h/2 + h/2 }
  if node.align.y == top    { y-shift = +cell.h/2 - h/2 }

  let origin = cetz.vector.add((cell.x, cell.y), (x-shift, y-shift))

  let body = text(top-edge: "cap-height", bottom-edge: "baseline", node.body)
  
  let (group-callback,) = cetz.draw.group({
    cetz.draw.translate(origin)
    (node.shape)(node)
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