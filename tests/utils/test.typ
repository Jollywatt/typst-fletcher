#set page(width: auto, height: auto, margin: 1em)
#import "/src/utils.typ": *

#assert(point-is-in-rect((1, 2), (center: (1, 2), size: (0,0))))
#assert(not point-is-in-rect((1, 11), (center: (0, 0), size: (1,10))))

#let points = (
	(0pt,0pt),
	(-2pt,80pt),
	(-1cm,5mm),
)
#assert(points.all(point => point-is-in-rect(point, bounding-rect(points))))
