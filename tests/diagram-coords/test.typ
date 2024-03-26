#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import fletcher.vector
#import fletcher: interp, interp-inv, xy-to-uv, uv-to-xy

// test `interp()` and `interp-inv()` are inverses

#let values = (1pt, 2pt, 4pt)
#let indices = (-1, 0, 0.5, 1, 1.75, 3, 4)

#for i in indices {
	let value = interp(values, i, spacing: 10pt)
	let i2 = interp-inv(values, value, spacing: 10pt)
	assert(i == i2)
}

#for v in values {
	let index = interp-inv(values, v , spacing: 10pt)
	let v2 = interp(values, index, spacing: 10pt)
	assert(v == v2)
}



// test `uv-to-xy()` and `xy-to-uv()` are inverses

#for grid in (
	(
		origin: (0, 0),
		axes: (ltr, ttb),
	),
	(
		origin: (1, -1),
		axes: (ttb, rtl),
	),
) {
	let grid = grid + (
		cell-sizes: (
			(36pt, 72pt, 24pt),
			(12pt, 48pt)
		),
		spacing: (12pt, 48pt),
	)
	grid += fletcher.interpret-axes(grid.axes)
	grid += fletcher.compute-cell-centers(grid)

	for uv in ((0,0), (1,2), (-5.5, 0.75), (3,1.125)) {
		let xy = uv-to-xy(grid, uv)
		assert(uv == xy-to-uv(grid, xy))
		assert(xy == uv-to-xy(grid, uv))


		// assert(vector.add(uv-to-xy(grid, uv), (0pt, 10pt)) ==
		// 	uv-to-xy-shifted(grid, uv, (0pt, 10pt)))
		// assert(uv-to-xy(grid, vector.add(uv, (0, 1))) ==
		// 	uv-to-xy-shifted(grid, uv, (0, 1)))
	}
}
