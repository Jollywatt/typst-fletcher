#set page(width: auto, height: auto, margin: 1em)
#import "/src/deps.typ": cetz
#import "/src/edges.typ": edge


Edges as CeTZ wrappers

#cetz.canvas({
  import cetz.draw: *

  let obj = bezier((0,0), (3,0), (1,1), (2,-1))
  obj

  for m in (
    "<->",
    "<<->>",
    "<|-|>",
    "<{-}>",
    "[-]",
    "|-|",
    "]-[",
    ">-<",
    ">>-<<",
    "|>-<|",
    "}>-<{",
  ) {
    translate(y: -.4)
    edge(obj, m, stroke: 1pt)
  }

})