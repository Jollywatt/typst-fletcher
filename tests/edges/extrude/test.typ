#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
    edge((0,0), "<->", (1,0))
    edge((0,0), "<=>", (1,0))
    edge((0,0), "<==>", (1,0))
    edge((0,0), "<->", (1,0), extrude: (+1, -1))
    edge((0,0), "<->", (1,0), extrude: (+2pt, 0, -2pt))
    edge((0,0), "<->", (1,0), extrude: (+0.1em, -0.1em))
}.intersperse(cetz.draw.translate(y: -.4)).flatten())