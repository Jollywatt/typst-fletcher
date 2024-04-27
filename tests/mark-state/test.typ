#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#diagram(edge("<->"))

#fletcher.MARKS.update(m => m + (
	"<": (inherit: "stealth", rev: true),
	">": (inherit: "stealth", rev: false),
))

#diagram(edge("<->"))
