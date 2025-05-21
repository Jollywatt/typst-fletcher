#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#for i in (
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

  // Panic
  // (-1, 50%),  // Segment must be non-negative
  // (3, 50%),  // Segment out of range
) {
  diagram(
    debug: 0,

    edge-corner-radius: 10pt,

    {
      edge((0, 0), "d,drr,ddd", "-}>",
        [#i],
        label-side: center,
        label-pos: i,
      )
    }
  )

  pagebreak(weak: true)
}
