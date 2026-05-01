#import "common.typ"
#import common: fletcher

// cover page

#v(10%)

#align(center)[
  #stack(
    spacing: 17pt,
    {
      import fletcher: diagram, edge, node
      set text(1.3em)
      diagram(
        spacing: 27mm,
        node((0, 1), $A$),
        node((1, 1), $B$),
        edge((0, 1), (1, 1), $f$, ">>->", stroke: 1pt),
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

  *Version #common.VERSION*
]

#v(1fr)


#columns(2)[
  #show heading: it => align(center, box(width: 100%, it)) + v(.8em)
  #outline(
    title: [Manual],
    target: selector(heading).after(<manual>, inclusive: false).before(<func-ref>, inclusive: false),
  )
  #colbreak()
  #outline(
    title: [Function Reference],
    target: selector(heading).after(<func-ref>, inclusive: false).before(<end>),
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
  include "sections/intro.typ"
  include "sections/diagrams.typ"
  include "sections/nodes.typ"
  include "sections/edges.typ"
  include "sections/marks.typ"
  include "sections/cetz.typ"
}


= Function Reference <func-ref>

#import "components.typ": *
#let exports = common.EXPORT_TREE.fletcher
#show raw.where(lang: "example"): common.example
#show raw.where(lang: "svg"): it => eval(it.text, mode: "code", scope: common.scope)
#set raw(lang: "typc")

#show-fn(exports.remove("diagram"), level: 2)
#show-fn(exports.remove("node"), level: 2)
#show-fn(exports.remove("edge"), level: 2)
#show-fn(exports.remove("flexigrid"), level: 2)


== The `marks` module

#show-fn(exports.marks.remove("test"))
#for name in exports.marks.keys() {
  show-fn(exports.marks.remove(name))
}


== The `shapes` module

These are the built in @node-shapes[node shapes], usable with the @node.shape option.

#common.shapes-gallery

#for name in exports.shapes.keys() {
  show-fn(exports.shapes.remove(name))
}


== The `paths` module

#show-fn(exports.edges.remove("apply-edge-effects"))
#show-fn(exports.paths.remove("path-effect"))
#show-fn(exports.paths.remove("trim-path"))
#show-fn(exports.paths.remove("trim-to-intersection"))
#for name in exports.paths.keys() {
  show-fn(exports.paths.remove(name))
}


== The `parsing` module

#for name in exports.parsing.keys() {
  show-fn(exports.parsing.remove(name))
}


== Docstrings not in this manual
#exports

#metadata(none) <end>
