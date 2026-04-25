#import "@preview/tidy:0.4.3"
#import "../src/exports.typ" as fletcher

#import "common.typ"

#let VERSION = toml("/typst.toml").package.version


// cover page
#v(10%)

#align(center)[
	#stack(
		spacing: 17pt,
		{
      import fletcher: diagram, node, edge 
			set text(1.3em)
			diagram(
				spacing: 27mm,
				node((0,1), $A$),
				node((1,1), $B$),
				edge((0,1), (1,1), $f$, ">>->", stroke: 1pt),
			)
		},
		text(3.2em, emph[fletcher]),
		[_(noun) a maker of arrows_],
	)

	#v(30pt)

	A #link("https://typst.app/")[Typst] package for diagrams with lots of arrows,
	built on top of #link("https://cetz-package.github.io")[CeTZ].

	#emph[
	Commutative diagrams,
	flow charts,
	state machines,
	block diagrams...
	]

	#link("https://github.com/Jollywatt/typst-fletcher")[`github.com/Jollywatt/typst-fletcher`]

	*Version #VERSION*
]

#v(1fr)


#columns(2)[
  #show heading: it => align(center, box(width: 100%, it)) + v(.8em)
	#outline(
		title: [Manual],
		target: selector(heading)
      .after(<manual>, inclusive: false)
      .before(<func-ref>, inclusive: false),
	)
	#colbreak()
	#outline(
		title: [Function Reference],
		target: selector(heading).after(<func-ref>, inclusive: false),
    depth: 2,
	)

]

#v(1fr)



#show heading: it => {
  let size = (40pt, 25pt, 20pt, 15pt).at(it.level, default: 10pt)
  text(size, it)
}
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  align(center, text(weight: 200, smallcaps(it)))
  line(length: 100%)
}

#show link: it => underline(strong(it))
#show ref: common.show-ref

= Manual <manual>

#{
  set heading(offset: 1)
  include "sections/1-intro.typ"
  include "sections/2-diagrams.typ"
  include "sections/3-nodes.typ"
  include "sections/4-edges.typ"
  include "sections/5-marks.typ"
  include "sections/6-cetz.typ"
}



= Function Reference <func-ref>

#let DOCSTRINGS = {
  tidy.parse-module(read("../src/diagram.typ")).functions
  tidy.parse-module(read("../src/flexigrid.typ")).functions
  tidy.parse-module(read("../src/nodes.typ")).functions
  tidy.parse-module(read("../src/edges.typ")).functions
  tidy.parse-module(read("../src/paths.typ")).functions
  tidy.parse-module(read("../src/marks.typ")).functions
  tidy.parse-module(read("../src/shapes.typ")).functions
  tidy.parse-module(read("../src/parsing.typ")).functions
}.map(fn => (fn.name, fn)).to-dict()


#let insert-at-path(dict, path, value) = {
  if path.len() > 0 {
    let p = path.remove(0)
    dict + ((p): insert-at-path(dict.at(p, default: (:)), path, value))
  } else {
    dict.insert(value, value)
    dict
  }
}

// dictionary reflecting the entire package submodule structure
#let exports = (:)
#for (name, path) in common.FUNCTION_PATHS {
  if name in DOCSTRINGS {
    exports = insert-at-path(exports, path, name)
  }
}
#let exports = exports.fletcher



#let show-type(type) = { 
  import tidy.styles.default: colors
  h(2pt)
  let clr = colors.at(type, default: colors.default)
  box(outset: 2pt, fill: clr, radius: 2pt, raw(type, lang: none))
  h(2pt)
}


#let rich-ref(id, ..args) = [
  #metadata(args.named())
  #label(id)
]


#let show-function-signature(fn) = {
  show: par
	set text(font: "DejaVu Sans Mono", size: 0.8em)

  if fn.name in common.FUNCTION_PATHS {
    text(common.FUNCTION_PATHS.at(fn.name).join(".") + ".")
  } else {
    text(red)[unexported: ]
  }

	text(fn.name, fill: tidy.styles.default.colors.signature-func-name)
	"("

	let inline = fn.args.len() <= 2
	if not inline { "\n  " }

	let items = fn.args.pairs().map(((arg-name, info)) => {

		if info.at("description", default: "") == "" {
			arg-name
		} else {
			link(label(fn.name + "." + arg-name), arg-name)
		}

		if "types" in info {
			": " + info.types.map(show-type).join(" ")
		}
	})

	items.join( if inline {", "} else { ",\n  "})
	if not inline { ",\n" } + ")"

	if fn.return-types != none {
		" -> "
		fn.return-types.map(show-type).join(" ")
	}
}

#let show-function-argument(fn, arg, info) = {
  
  rich-ref(
    fn.name + "." + arg,
    entity: "argument",
    function: fn.name,
    argument: arg,
  )

  let first-line = {
    strong(raw(arg))
    if "types" in info {
      h(0.5em)
      info.types.map(show-type).join(text(0.8em)[ or ])
    }
    if "default" in info {
      text(0.8em)[ default ]
      raw(info.default)
    }
    h(1fr)
    link(label(fn.name), text(gray, $arrow.tl$))
  }

  let is-long = info.description.len() > 500
  block(
    inset: 10pt,
    breakable: is-long,
    {
      block(
        outset: 10pt,
        width: 100%,
        radius: 10pt,
        stroke: (top: .6pt + gray),
        first-line,
      )
      eval(info.description, mode: "markup", scope: common.scope)
    },
  )
}



#let show-fn(name) = {
  let fn = DOCSTRINGS.at(name)
  state("current-function").update(fn.name)

  rich-ref(fn.name, entity: "function", function: fn.name)
  [=== #raw(fn.name + "()")]

  eval(fn.description, mode: "markup", scope: common.scope)

  show-function-signature(fn)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    show-function-argument(fn, arg, info)
    v(1em)
  }
}



#show raw.where(lang: "example"): common.show-example


== Main functions

#show-fn(exports.remove("diagram"))
#show-fn(exports.remove("node"))
#show-fn(exports.remove("edge"))
#show-fn(exports.remove("flexigrid"))


== Module `marks`

#show-fn(exports.marks.remove("test"))
#for name in exports.marks.keys() {
  show-fn(exports.marks.remove(name))
}


== Module `shapes`

These are the built in node shapes, usable with the @node.shape option.

#grid(
  columns: (1fr,)*5,
  align: center + horizon,
  inset: 0.5em,
  ..fletcher.shapes.NODE_SHAPES.keys()
    .filter(name => name != "none")
    .enumerate()
    .map(((i, name)) => {
      let c = color.oklch(80%, 70%, 20deg*i)
      let body = text(c.mix(black), pad(-1em, link(label(name), pad(1em, raw(name)))))
      fletcher.diagram(fletcher.node((0,0), body, shape: name, stroke: c))
    })
)

#for name in exports.shapes.keys() {
  show-fn(exports.shapes.remove(name))
}


== Module `paths`

#show-fn(exports.paths.remove("path-effect"))
#show-fn(exports.paths.remove("trim-path"))
#show-fn(exports.paths.remove("trim-to-intersection"))
#for name in exports.paths.keys() {
  show-fn(exports.paths.remove(name))
}


== Module `parsing`

#for name in exports.parsing.keys() {
  show-fn(exports.parsing.remove(name))
}


== Docstrings not in this manual
#exports

