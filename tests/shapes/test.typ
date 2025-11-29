#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#for (i, shape) in fletcher.shapes.NODE_SHAPES.keys().enumerate() {
  let c = color.hsv(i*40deg, 50%, 100%)
  diagram(node((0,0), [#shape],
    shape: shape,
    fill: c,
    stroke: c.darken(20%),
    extrude: (0, 2),
  ))
  linebreak()
}