#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#cetz.canvas({
  cetz.draw.circle((0,0), radius: 0.5, fill: green, name: "start")
  cetz.draw.circle((2,1), radius: 0.25, fill: red, name: "stop")
  edge(<start>, <stop>, "->")
  edge(<start>, <stop>, "->", bend: 90deg)
  edge(<start>, "r,d,l", <start>, "->")
})