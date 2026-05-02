#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#diagram({
  node((0,0), [Node label as positional argument], <a>, fill: yellow)
  cetz.draw.circle("a.north-east", radius: 1pt)
})

#diagram({
  node((0,0), <a>)
  node((-1,-1), <b>)
  edge(<a>, "->", <b>, [Nodes with labels and no body])
})
