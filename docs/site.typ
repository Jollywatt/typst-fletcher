#let sections = (
  "intro": "Intro",
  "diagrams": "Diagrams",
  "nodes": "Nodes",
  "edges": "Edges",
  "marks": "Marks",
  "cetz": "CeTZ Integration",
)

#for (i, (file, name)) in sections.pairs().enumerate() [
  #let it = include "/docs/sections/" + file + ".typ"
  #document("manual/" + file + "/index.html", it, title: name)
  #label(file)
  #asset(
    "manual/" + file + "/frontmatter.md",
    ```
    ---
    title: "{TITLE}"
    weight: {NUM}
    ---
    ```
      .text
      .replace("{TITLE}", name)
      .replace("{NUM}", str(i + 1)),
  )
]

#asset(".gitignore", "*")

#asset(
  "manual/_index.md",
  ```
  ---
  weight: 1
  bookFlatSection: true
  bookCollapseSection: false
  title: "Manual"
  ---
  ```.text,
)



#asset(
  "reference/_index.md",
  ```
  ---
  weight: 2
  bookFlatSection: true
  bookCollapseSection: false
  title: "Reference"
  ---
  ```.text,
)

#import "common.typ"
#show: common.style

#let fn-doc(modules, name) = {
  document("reference/" + modules + "/" + name + "/index.html", common.show-fn(name))
  asset(
    "reference/" + modules + "/" + name + "/frontmatter.md",
    ```
    ---
    title: "{TITLE}"
    ---
    ```
      .text
      .replace("{TITLE}", name),
  )
}


#fn-doc("", "diagram")
#fn-doc("", "node")
#fn-doc("", "edge")
#fn-doc("marks", "test")
// #document("reference/node/index.html", common.show-fn("node"))
// #document("reference/edge/index.html", common.show-fn("edge"))

// == The `paths` module

#let exports = common.EXPORT_TREE

#fn-doc("path", exports.edges.remove("apply-edge-effects"))
#fn-doc("path", exports.paths.remove("path-effect"))
#fn-doc("path", exports.paths.remove("trim-path"))
#fn-doc("path", exports.paths.remove("trim-to-intersection"))
#for name in exports.paths.keys() {
  fn-doc("path", exports.paths.remove(name))
}

#asset(
  "reference/marks/_index.md",
  ```
  ---
  bookCollapseSection: true
  title: "The marks module"
  ---
  ```.text,
)
#asset(
  "reference/path/_index.md",
  ```
  ---
  bookCollapseSection: true
  title: "The path module"
  ---
  ```.text,
)

#document("gallery/index.html")[
  = Gallery!
]
#asset(
  "gallery/frontmatter.md",
  ```
  ---
  title: "Gallery"
  weight: 1
  bookFlatSection: true
  ---
  ```.text,
)
