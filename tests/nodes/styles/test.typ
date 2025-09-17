#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#page[
  Node shape inference
  #diagram(
    cetz.draw.set-style(node: (stroke: 1pt)),
    cetz.draw.scale(y: -1),
    node((0,0), `height`, height: 2),
    node((1,0), `width`, width: 2),
    node((0,1), `radius`, radius: auto),
    node(enclose: ((0,2), (1,2)), `corner-radius`, corner-radius: 5pt),
  )
]

#page[
  Node styles
  #diagram({
    import cetz.draw: *
    scale(y: -1)

    set-style(fill: red) // should not affect nodes
    set-style(node: (stroke: 1pt + blue))
    set-style(node: (corner-radius: 2pt))
  
    node((0,0), [blue])
    node((1,0), [black], stroke: black)

    group({
      set-style(node: (stroke: none, fill: red))
      set-style(node: (circle: (fill: yellow)))
      node((0,1), emph[Yellow], radius: 0.6)
      node((1,1), emph[Teal], radius: 0.6, fill: teal)
    })

    set-style(node: (stroke: 0.5pt, fill: luma(90%)))
    node((0,2), [Double], extrude: (0, 3))
    node((1,2), [Pad], inset: 15pt, shape: "circle")
  })
]

#page[
  Empty nodes are point-like \
  unless a size is given
  #diagram(
    debug: "grid node",
    node((0,0)),
    node((1,0.5)),
    node((2,1), stroke: 1pt, radius: 5pt),
  )
]

// TODO: test error messages
// #diagram(node((0,0), frobnicate: 42))
