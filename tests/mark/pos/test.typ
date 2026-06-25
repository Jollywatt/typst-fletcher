#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  let n = 4
  for i in range(n + 1) {
    let x = i/n
    edge(marks: ((inherit: "|>", pos: x),))
    cetz.draw.translate(y: -.2)
  }
})