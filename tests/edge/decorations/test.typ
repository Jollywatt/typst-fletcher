#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  import cetz.draw: *
  for l in (1, 1.5, 2, 2.5, 3) {
    edge(line((0,0), (l,0)), "<->", decorate: "wave")
    translate(y: -0.5)
  }
})
