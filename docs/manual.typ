#import "@preview/tidy:0.4.3"
#import "../src/deps.typ": cetz
#import "../src/exports.typ" as fletcher

#let module-docs(path) = {
  [== #raw(path)]
  
  let docs = tidy.parse-module(read(path), scope: (
    cetz: cetz,
    fletcher: fletcher
  ))
  tidy.show-module(
    docs,
    style: tidy.styles.default
  )
}

= Manual

#module-docs("/src/nodes.typ")
#module-docs("/src/edges.typ")
#module-docs("/src/paths.typ")