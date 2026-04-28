#let body = context [
  #set heading(numbering: "1.")

  #show ref: it => {
    let id = str(it.target)
    let labels = query(it.target)
    let single = if target() == "paged" {
      labels.first()
    } else {
      labels.last()
    }
    link(single.location(), [Link from #target()])
  }

  #let richref(id) = {
    if target() == "paged" {
      label("-" + id)
    } else {
      label(id)
    }
  }

  == Title <a>

  See @a.
]
#document("test.pdf", body)
#document("test.html", body)

// #document("manual.pdf", include "manual.typ")

/*
// output an html file and frontmatter pair in the same directory
#let doc(dir, body, frontmatter: (:)) = {
  document(dir + "/index.html", body)
  asset(dir + "/frontmatter.md", "---\n" + yaml.encode(frontmatter) + "\n---")
}

#let sections = (
  "intro": "Intro",
  "diagrams": "Diagrams",
  "nodes": "Nodes",
  "edges": "Edges",
  "marks": "Marks",
  "cetz": "CeTZ Integration",
)

#for (i, (file, name)) in sections.pairs().enumerate() [
  #let body = include "/docs/sections/" + file + ".typ"
  // #document("manual/" + file + "/index.html", it, title: name)
  // #label(file)
  // #asset(
  //   "manual/" + file + "/frontmatter.md",
  //   ```
  //   ---
  //   title: "{TITLE}"
  //   weight: {NUM}
  //   ---
  //   ```
  //     .text
  //     .replace("{TITLE}", name)
  //     .replace("{NUM}", str(i + 1)),
  // )
  #doc("manual/sections/" + file, body, frontmatter: (
    title: name,
    weight: i + 1,
  ))
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

#let exports = common.EXPORT_TREE.fletcher

#let module-doc(name) = {
  asset(
    "reference/" + name + "/_index.md",
    ```
    ---
    bookCollapseSection: true
    title: "The {TITLE} module"
    ---
    ```
      .text
      .replace("{TITLE}", name),
  )
}

#fn-doc("", exports.remove("diagram"))
#fn-doc("", exports.remove("node"))
#fn-doc("", exports.remove("edge"))
#fn-doc("", exports.remove("flexigrid"))

#module-doc("marks")
#fn-doc("marks", exports.marks.remove("test"))

#module-doc("path")
#fn-doc("path", exports.edges.remove("apply-edge-effects"))
#fn-doc("path", exports.paths.remove("path-effect"))
#fn-doc("path", exports.paths.remove("trim-path"))
#fn-doc("path", exports.paths.remove("trim-to-intersection"))
#for name in exports.paths.keys() {
  fn-doc("path", exports.paths.remove(name))
}




#doc("reference/shapes/", frontmatter: (title: "Cool!"))[whow]

// #document("reference/shapes/index.html")[
//   == The `shapes` module

//   These are the built in node shapes, usable with the @node.shape option.

//   #import common.fletcher
//   #grid(
//     columns: (1fr,) * 5,
//     align: center + horizon,
//     inset: 0.5em,
//     ..fletcher
//       .shapes
//       .NODE_SHAPES
//       .keys()
//       .filter(name => name != "none")
//       .enumerate()
//       .map(((i, name)) => {
//         let c = color.oklch(80%, 70%, 20deg * i)
//         let body = text(c.mix(black), pad(-1em, link(label(name), pad(1em, raw(name)))))
//         fletcher.diagram(fletcher.node((0, 0), body, shape: name, stroke: c))
//       })
//   )
// ]

#for name in exports.shapes.keys() {
  fn-doc("shapes", exports.shapes.remove(name))
}


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
