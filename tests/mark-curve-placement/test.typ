#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import fletcher.cetz.draw

#let curve(t) = (t*1cm, 0pt)
#let samples = 100
#let ts = range(samples + 1).map(t => t/samples)
// #let marks = fletcher.interpret-marks(("head", "head"))
#let mark = (
	angle: 30deg,
	size-l: 5,
	size-r: 10,

	tail-origin: -6,
	tip-end: -6,

	fill: none,
	draw: mark => {
		draw.line(
			(0, 0),
			(180deg + mark.angle, mark.size-l),
			(180deg - mark.angle, mark.size-r),
			close: true,
		)
	},

	cap-offset: (mark, y) => if mark.tip {
		-0.57*y
	} else {
		0
	},
)
#let marks = (0, 0.1, 0.5, 1).map(pos => fletcher.MARKS.head + (pos: pos, rev: false)).map(fletcher.resolve-mark)

#fletcher.mark-debug(mark)

#fletcher.cetz.canvas({
	draw.line(..ts.map(curve), stroke: rgb("0003") + 1pt)

	marks.map(mark => {
		fletcher.place-mark-on-curve(mark, curve, debug: true)
	}).join()
})
