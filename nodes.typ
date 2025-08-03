#import "shapes.typ"

#let node(
  pos,
  body,
  name: none,
  align: center + horizon,
  shape: shapes.rect,
  weight: 1,
) = {
  ((
    class: "node",
    pos: pos,
    body: body,
    name: name,
    align: align,
    shape: shape,
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
  
  cetz.draw.group({
    cetz.draw.translate(origin)
    (node.shape)(node)
  }, name: node.name)
}