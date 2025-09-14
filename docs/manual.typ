#import "@preview/tidy:0.4.3"
#import "../src/deps.typ": cetz
#import "../src/exports.typ" as fletcher

#include "cover.typ"

#let module-docs(name) = {
  [== #raw(name)]
  
  let path = "/src/" + name + ".typ"
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

#import "common.typ": style
#show: style.with(refs: true)


= Manual

#{
  set heading(offset: 1)
  include "sections/1-intro.typ"
  include "sections/2-diagrams.typ"
  include "sections/3-nodes.typ"
  include "sections/4-edges.typ"
  include "sections/5-marks.typ"
  include "sections/6-cetz.typ"
}


= Reference <func-ref>

#module-docs("nodes")
#module-docs("edges")
#module-docs("flexigrid")
#module-docs("paths")