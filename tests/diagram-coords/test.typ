#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge

#let values = (1pt, 2pt, 4pt)
#let indices = (-1, 0, 0.5, 1, 1.75, 3, 4)
#for i in indices {
	let value = fletcher.interp(values, i, spacing: 10pt)
	let j = fletcher.interp-inv(values, value, spacing: 10pt)
	assert(i == j)
}
