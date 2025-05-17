#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
  debug: 0,

  edge-corner-radius: 10pt,

  {
    for i in (
      (0, -50%),
      (0, 0%),
      (0, 50%),
      (0, 100%),
      (0, 150%),

      (1, 50%),

      (2, -0.5),
      (2, 0),
      (2, 12pt),
      (2, 0.25),
      (2, 0.5),
      (2, 0.75),
      (2, 100%-6pt),
      (2, 100%+6pt),

      (3, 50%),
    ) {
      edge((0, 0), "d,drr,ddd", "-}>",
        [#i],
        label-side: center,
        label-pos: i,
      )
    }
  }
)
