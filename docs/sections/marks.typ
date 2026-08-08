#import "../common.typ": *
#show: style
#import "/src/parsing.typ": LINE_ALIASES


= Marks and Arrows

Arrow marks may be specified like `edge(from, "->", to)` or `edge(..pts, "->")` or with the @edge.marks option.
Some mathematical arrow heads are supported which match the symbols $arrow$, $arrow.double$, $arrow.triple$, $arrow.bar$, $arrow.twohead$, and $arrow.hook$ in the default font.


#frame-row(..(
  "->",
  "=>",
  "==>",
  "|->",
  "->>",
  "hook->",
).map(marks => {
  diagram(
    edge-stroke: 0.9pt,
    edge((0,0), (1,0), marks, label: raw(repr(marks)), label-sep: 1em),
    edge((0,1), (1,1), marks, bend: 50deg),
  )
}))


A few other built-in marks are provided, and all marks can be placed at any position along an edge.


#frame-row(..(
  "<-<<",
  "--|>--",
	"harpoon'=harpoon",
  "<-x-hook",
  ")=/=>",
).map(marks => {
  diagram(
    edge-stroke: 0.9pt,
    edge((0,0), (1,0), marks, label: raw(repr(marks)), label-sep: 1em),
  )
}))



== Built-in marks and line styles

A mark shorthand such as `"<->"` consists of _mark names_ `"<"` and `">"` joined with _line styles_, `"-"`.

The built-in line styles are:

#context frame-row(..LINE_ALIASES.keys().map(m => {
  let m = m + ">"
  diagram(edge((0mm,0), (20mm,0), stroke: 1pt, marks: m, label: raw(repr(m)), label-sep: 1em))
}))

It is possible to rename, redefine, and define your own marks, but the built-in marks are:

#context frame-row(..fletcher.marks.MARKS.get().keys().sorted(key: it => upper(it) != it).map(m => {
  diagram(edge((0mm,0), (20mm,0), stroke: 1pt, marks: (m, m), label: raw(m, lang: none), label-sep: 1em))
}))

Marks can be flipped by appending `'` to the name.

#example(```typ
Normal #diagram(edge("hook-harpoon", stroke: 1pt))
and flipped #diagram(edge("hook'-harpoon'", stroke: 1pt))
```)

Some marks adapt to the edge's @edge.extrude[extrusion], including `">"`, `"harpoon"`, `"harpoons"`, `"hook"` and `"hooks"`:

#example(```typ
#diagram(
	edge-stroke: 1pt,
	edge((0,0), (1,0), "->"),
	edge((0,1), (1,1), "=>"),
	edge((0,2), (1,2), "==>"),
	edge((2,0), (3,0), "harpoon'-harpoon"),
	edge((2,1), (3,1), "harpoon'=harpoon"),
	edge((2,2), (3,2), "harpoon'==harpoon"),
)
```)

#import "/src/parsing.typ": LINE_ALIASES



== Adjusting marks

While shorthands like `"--|>"` exist, finer control is possible.
Under the hood, shorthands are expanded into _full form_: for example, `edge("--|>")` is the same as #raw("edge" + repr(fletcher.parsing.parse-mark-shorthand("--|>"))).
This expansion is done by @parse-mark-shorthand:
#example(```typ
#fletcher.parsing.parse-mark-shorthand("--|>")
```)

For more control, you can use the full form and pass an array of marks to the @edge.marks argument.
This lets you pass @mark-objects[_mark objects_] instead of mark names, which are dictionaries of mark parameters which you can customise.
For example, here is a tulip made of arrows:

#example(```typ
#diagram(
	edge-stroke: 1.5pt,
	edge((0,3), (-0.1,0), bend: -8deg, marks: (
		(inherit: ">>", size: 6, delta: 70deg, sharpness: 65deg),
		(inherit: "head", rev: true, pos: 0.8, sharpness: 0deg, size: 17),
		(inherit: "bar", size: 1, pos: 0.3),
		(inherit: "solid", size: 12, rev: true, stealth: 0.1, fill: red.mix(purple)),
	), stroke: green.darken(50%)),
)
```)

In this example, mark objects are based off previously defined marks (using the `inherit` parameter) with other parameters customised.

=== Listing mark parameters

You can see the parameters of built-in marks by inspecting the mark object which is stored in the `fletcher.marks.DEFAULT_MARKS` dictionary:
#example(```typ
`>` = #fletcher.marks.DEFAULT_MARKS.at(">")

`head` = #fletcher.marks.DEFAULT_MARKS.at("head")
```)
As you can see, the basic `head` mark (which `>` and `<` inherit from) has quite a few parameters:
- `size` is the overall size in units of the edge's stroke thickness
- `sharpness` is the angle formed at the tip
- `delta` is the angle of the arc spanned by the legs of the arrow
- ...and @special-mark-props[other parameters] which are common to all marks
// - ```plain tip/tail-origin/end/hang``` are all metrics for adjusting various mark alignments (see @mark-anatomy)
// - `draw` contains CeTZ objects of the mark centered at the coordinate origin and pointing to the right
// - `stroke` (and `fill` is applicable) control the default styles for CeTZ objects
// - `cap-offset` controls where the edge stroke ends

=== Tweaking mark parameters

To adjust a mark, create a mark object that inherits from the mark and overrides any parameters.
For example, here is a smaller, pointerer version of the `">"` mark:
#let mark-code = ```typ
#let my-mark = (inherit: ">", size: 3, sharpness: 5deg)
```
#mark-code
#example(```typ
#diagram(edge(stroke: 2pt, "->"))

#diagram(edge(stroke: 2pt, marks: (none, my-mark)))
```, setup: mark-code)



== Mark objects <mark-objects>

A _mark object_ is a dictionary of parameters, which must include a `draw` entry or an `inherit` entry which points to another mark object.
The `draw` entry eventually contains CeTZ objects which are translated and scaled to fit the edge; the mark should be centered at `(0, 0)` and pointing right, and the stroke's thickness is defined as the unit length.

As a minimal example, here is a basic circle mark object:

#example(```typ
#import cetz.draw
#let my-mark = (
	draw: draw.circle((0,0), radius: 2, fill: none)
)
#diagram(
  edge-stroke: 2pt,
	edge((0,0), (1,0), marks: (my-mark, my-mark), bend: 30deg),
	edge((0,1), (1,1), marks: (none, my-mark), stroke: teal),
)
```)

A mark object can contain arbitrary _parameters_, which can be adjusted to customise the mark.
Any entry in a mark object can depend on parameters defined earlier by writing it as a function `mark => (..)`, where `mark` is a dictionary containing the preceding computed parameter values.

For example, our mark object from above could also be written as:

```typ
#let my-mark = (
	size: 2,
	draw: mark => draw.circle((0,0), radius: mark.size, fill: none)
)
```
The `size` parameter makes it easy to adjust out new mark:

#example(setup: ```typ
#import cetz.draw
#let my-mark = (
	size: 2,
	draw: mark => draw.circle((0,0), radius: mark.size, fill: none)
)
```, ```typ
#diagram(edge(marks: (my-mark + (size: 3), my-mark), stroke: 3pt))
```)

Lastly, mark objects may _inherit_ properties from other marks in `fletcher.MARKS` by containing an `inherit` entry, for example:

#example(```typ
#let my-mark = (
	inherit: "stealth",
	fill: red,
	stroke: none,
	extrude: (0, -3),
)
#diagram(edge("rr", stroke: 2pt, marks: (
  my-mark, my-mark + (fill: blue))))
```)

Internally, marks are passed to `resolve-mark()`, which resolves all entries to their final values.

=== Special mark properties <special-mark-props>

A mark object may contain arbitrary properties, but the following have special functions.

#{
	show table.cell.where(y: 0): emph
	set par(justify: false)
	let little-mark(..args) = frame(diagram(spacing: 5mm, edge(..args, stroke: 0.75pt)))

	table(
		columns: 3,
		stroke: (x: none),

		table.header([Name], [Description], [Default]),

		`inherit`,
		[
			The name of a mark in `fletcher.marks.DEFAULT_MARKS` to inherit properties from.
			This can be used to make mark aliases, for instance, `"<"` is defined as `(inherit: "head", rev: true)`.
		],
		none,

		`draw`,
		[
			As described above, this contains the final CeTZ objects to be drawn. Objects should be centered at $(0,0)$ and be scaled so that one unit is the stroke thickness.
			The default `stroke` and `fill` is inherited from the edge's style.
		],
		none,

		`pos`,
		[
			Location of the mark along the edge, from `0` (start) to `1` (end).
		],
		`auto`,

		[`fill`\ `stroke`],
		[
			The default fill and stroke styles for CeTZ objects returned by `draw`.
			If `none`, polygons will not be filled/stroked by default, and if `auto`, the style is inherited from the edge's stroke style.
		],
		`auto`,

		`rev`,
		[
			Whether to reverse the mark so it points backwards.

		],
		`false`,

		`flip`,
		[
			Whether to reflect the mark across the edge; the difference between
			#frame(diagram(spacing: 8mm, edge("hook-", stroke: 1pt)))
			and
			#frame(diagram(spacing: 8mm, edge("hook'-", stroke: 1pt))), for example.
			A suffix `'` in the name, such as `"hook'"`, results in a flip.
		],
		`false`,

		`scale`,
		[
			Overall scaling factor. See also @edge.mark-scale.
		],
		`100%`,

		`extrude`,
		[
			Whether to duplicate the mark and draw it offset at each extrude position.
			For example, `(inherit: "head", extrude: (-5, 0, 5))` looks like
			#frame(diagram(spacing: 8mm, edge(marks: (none, (inherit: "head", extrude: (-5, 0, 5))), stroke: .7pt)))).

		],
		`(0,)`,

		[`tip-origin`\ `tail-origin`],
		[
			These two properties control the $x$ coordinate of the point of the mark, relative to $(0, 0)$. If the mark is acting as a tip (#little-mark("->") or #little-mark("<-")) then `tip-origin` applies, and `tail-origin` applies when the mark is a tail (#little-mark("-<") or #little-mark(">-")).
			See `mark-debug()`.
		],
		`0`,

		[`tip-end`\ `tail-end`],
		[
			These control the $x$ coordinate at which the edge's stroke terminates, relative to $(0, 0)$.
			See `mark-debug()`.
		],
		`0`,

		`cap-offset`,
		[
			A function `(mark, y) => x` returning the $x$ coordinate at which the edge's stroke terminates relative to `tip-end` or `tail-end`, as a function of the $y$ coordinate.
			This is relevant for @edge.extrude[extruded] edges.
			See `cap-offset()`.
		],
		none,

	)
}

The last few properties control the fine behaviours of how marks connect to the target point and to the edge's stroke.
Briefly, a mark has four possibly-distinct center points.
It is easier to show than to tell:


See `mark-debug()` and `cap-offset()` for details.
