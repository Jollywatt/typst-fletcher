#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(
	node((0,0), [A], name: <a>),
	node((2,0), [B], name: "b"),
	edge(<a>, <b>, [by label], ">>-}>"),
	edge(<a>, "rrr", "--", snap-to: (<b>, auto))
)
