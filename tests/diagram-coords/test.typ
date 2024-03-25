#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge


// test `interp()` and `interp-inv()` are inverses

#let values = (1pt, 2pt, 4pt)
#let indices = (-1, 0, 0.5, 1, 1.75, 3, 4)

#for i in indices {
	let value = fletcher.interp(values, i, spacing: 10pt)
	let i2 = fletcher.interp-inv(values, value, spacing: 10pt)
	assert(i == i2)
}

#for v in values {
	let index = fletcher.interp-inv(values, v , spacing: 10pt)
	let v2 = fletcher.interp(values, index, spacing: 10pt)
	assert(v == v2)
}



// test `uv-to-xy()` and `xy-to-uv()` are inverses

#let grid = (
	origin: (0, 0),
	axes: (ltr, ttb),
	cell-sizes: (
		(36pt, 72pt, 24pt),
		(12pt, 48pt)
	),
	spacing: (12pt, 48pt),
)
#{
	grid += fletcher.interpret-axes(grid.axes)
	grid += fletcher.compute-cell-centers(grid)
}

#grid

#fletcher.cetz.canvas(fletcher.draw-debug-axes(grid))

#fletcher.uv-to-xy(grid, (0,0))