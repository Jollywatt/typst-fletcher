#import "shapes.typ"

#let node(
  pos,
  content,
  name: none,
  align: center + horizon,
  shape: shapes.rect,
) = {
  ((
    class: "node",
    pos: pos,
    content: content,
    name: name,
    align: align,
    shape: shape,
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

  let coord = (to: (cell.x, cell.y), rel: (x-shift, y-shift))

  let body = text(top-edge: "cap-height", bottom-edge: "baseline", node.content)
  cetz.draw.content(coord, body)
  
  (node.shape)(coord, node)
}