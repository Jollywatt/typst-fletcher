#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram({
  for s in (0.2, 0.5, 1, 1.5, 2) {
    edge(">->", mark-scale: s)
    cetz.draw.translate(y: -0.5)
  }
})


// todo: test diagram(mark-scale: x) and set-style(mark: (scale: x))