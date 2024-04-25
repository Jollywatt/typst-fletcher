#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: diagram, node, edge
#import fletcher.cetz.draw

#let mark = (
	angle: 30deg,
	size-l: 5,
	size-r: 10,

	tail-origin: -8,
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
	}
)

#fletcher.mark-debug(mark, show-offsets: true)
#fletcher.mark-demo(mark)
#diagram(edge(marks: (mark, mark), "triple"))
#diagram(edge(marks: ("hook", "hook"), "triple"))

#fletcher.mark-demo("hook")