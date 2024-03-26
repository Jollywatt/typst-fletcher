#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge, cetz
#import cetz.draw

#let grid = (
	origin: (0, -1),
	axes: (ltr, btt),
	centers: (
		(0cm, 1cm, 2cm, 4cm, 5cm),
		(0cm, 1cm, 2cm),
	),
	cell-sizes: (
		(5mm, 10mm, 0mm, 5mm, 5mm),
		(5mm, 10mm, 0mm),
	),
	spacing: (1cm, 1cm),
)

#let pip(coord, fill) = draw.circle(
	coord,
	radius: 2pt,
	stroke: none,
	fill: fill,
)

#((ltr, btt), (ltr, ttb), (rtl, ttb), (rtl, btt)).map(axes => {
	(axes, axes.rev()).map(axes => [
		#let grid = grid + (axes: axes) + fletcher.interpret-axes(axes)

		#grid.axes

		#cetz.canvas({
			fletcher.draw-debug-axes(grid)
			pip(fletcher.uv-to-xy(grid, (0,0)), red)
			pip(fletcher.uv-to-xy(grid, (1,0)), green)
			pip(fletcher.uv-to-xy(grid, (1,.5)), blue)
		})
	])
}).flatten().join(pagebreak())

