#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let pages = ((ltr, btt), (ltr, ttb), (rtl, btt), (rtl, ttb)).map(axes => {
	(axes, axes.rev()).map(axes => {
		diagram(
			axes: axes,
			node((0,0), $(0,0)$),
			edge((0,0), (1,0), "hook->"),
			node((1,0), $(1,0)$),
			node((1,1), $(1,1)$),
			node((0.5,0.5), raw(repr(axes))),
		)
	})
})

#pages.flatten().join(pagebreak())