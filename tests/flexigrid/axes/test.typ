#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz

#let all-axes = (
	(ltr, ttb),
	(ltr, btt),
  (rtl, ttb),
  (rtl, btt),
	(ttb, ltr),
	(btt, ltr),
  (ttb, rtl),
  (btt, rtl),
)

#for axes in all-axes {
  page[
    #axes \
    #diagram(
      debug: "grid",
      axes: axes,
      node((0,0), $(0,0)$),
      edge("->"),
      node((1,0), $(1,0)$),
      edge("->"),
      node((2,1), $(2,1)$),
    )
  ]
}

#pagebreak()

Cardinal directions `n,e,s,w` etc. are axes-invariant

https://github.com/Jollywatt/typst-fletcher/issues/104

#for axes in all-axes {
  diagram(
    axes: axes,
    node((0,0), [O]),
    edge("n,e,s,w", "..>"),
  )
}