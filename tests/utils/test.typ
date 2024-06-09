#set page(width: auto, height: auto, margin: 1em)
#import "/src/utils.typ": *

// this test contains no visual output
#show: none

= Points in rect

#assert(point-is-in-rect((1, 2), (center: (1, 2), size: (0,0))))
#assert(not point-is-in-rect((1, 11), (center: (0, 0), size: (1,10))))

#let points = (
	(0pt,0pt),
	(-2pt,80pt),
	(-1cm,5mm),
)
#assert(points.all(point => point-is-in-rect(point, bounding-rect(points))))


= Array interpolation

#let a = (22pt,)
#assert(interp(a, 0) == 22pt)
#assert(interp-inv(a, 22pt) == 0)

#let a = (10pt, 20pt, 25pt)
#assert(range(3).map(interp.with(a)) == a)
#assert(interp(a, 0.5) == 15pt)

Outside bounds

#assert(interp(a, 3) == interp(a, a.len() - 1))
#assert(interp(a, -1) == interp(a, 0))

#assert(interp(a, -1, spacing: 100pt) == a.at(0) - 100pt)
