#import "@preview/tidy:0.4.3"
#import "../src/deps.typ": cetz
#import "../src/exports.typ" as fletcher

#include "sections/cover.typ"

#let module-docs(path) = {
  [== #raw(path)]
  
  let docs = tidy.parse-module(read(path),
    label-prefix: "fletcher.",
    scope: (
      cetz: cetz,
      fletcher: fletcher
    ),
  )
  tidy.show-module(
    docs,
    style: tidy.styles.default
  )
}

#show link: it => {
  set text(blue.darken(50%), font: "CMU Bright")
  strong(it)
}

#import "sections/common.typ": style
#show: style

= Manual

#{
  set heading(offset: 1)
  include "sections/intro.typ"
}


== Edges <edges>

= Reference <func-ref>

#module-docs("/src/nodes.typ")
#module-docs("/src/edges.typ")
#module-docs("/src/flexigrid.typ")
#module-docs("/src/paths.typ")