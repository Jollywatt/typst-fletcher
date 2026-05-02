#import "../common.typ"
#import "../components.typ"

#show: common.style

#show math.equation.where(block: false): it => {
  box(html.frame(it))
}

#let encode-frontmatter(..args) = "---\n" + yaml.encode(args.named()) + "\n---"

// output an html file and frontmatter pair in the same directory
#let doc(dir, body, frontmatter: (:)) = {
  document(dir + "/_index.html", body)
  asset(dir + "/frontmatter.md", encode-frontmatter(..frontmatter))
}



#doc("", frontmatter: (title: "Fletcher"))[
  #html.div(class: "book-hero")[
    #components.logo

    A #link("https://typst.app/")[Typst] package for diagrams with lots of arrows,
    built on top of #link("https://cetz-package.github.io")[CeTZ].

    *Version #common.VERSION*
  ]

  #show: html.div.with(style: "text-align: center")

  #link("manual.pdf", html.img(src: "https://img.shields.io/badge/Manual-PDF-orange"))
  #link("https://typst.app/universe/package/fletcher/", html.img(src: "https://img.shields.io/badge/Typst-Universe-239dad"))
  #link("https://github.com/Jollywatt/typst-fletcher/", html.img(src: "https://img.shields.io/badge/GitHub-Repo-blue?logo=github"))
  #link("https://forum.typst.app", html.img(src: "https://img.shields.io/badge/ask-on%20Typst%20forum-239dad"))
  #link("https://discord.com/channels/1054443721975922748/1260973351900414102", html.img(src: "https://img.shields.io/badge/ask-on%20Discord-2a4d7e"))

  This is a #highlight[largely incomplete] web version of the manual for this package.

]



#doc("gallery/", frontmatter: (
  title: "Gallery",
  weight: 1,
  bookFlatSection: true,
))[
  = Gallery
]

#asset(
  "manual/_index.md",
  encode-frontmatter(
    weight: 1,
    bookFlatSection: true,
    bookCollapseSection: false,
    title: "Manual",
  ),
)


#let sections = (
  "intro": "Quick Overview",
  "diagrams": "Diagrams and Layout",
  "nodes": "Nodes",
  "edges": "Edges",
  "marks": "Marks and Arrows",
  "cetz": "CeTZ Integration",
)

#for (i, (file, name)) in sections.pairs().enumerate() [
  #let body = include "/docs/sections/" + file + ".typ"
  #doc("manual/" + file, body, frontmatter: (
    title: name,
    weight: i + 1,
  ))
]


#asset(
  "reference/_index.md",
  encode-frontmatter(
    weight: 2,
    bookFlatSection: true,
    bookCollapseSection: false,
    title: "Function Reference",
  ),
)


#let fn-doc(modules, name, ..args) = context {
  doc("reference/" + modules + "/" + name, components.show-fn(name, level: 1), frontmatter: (title: name, ..args.named()))
}

#let exports = common.EXPORT_TREE.fletcher

#let module-doc(name, ..args) = {
  asset(
    "reference/" + name + "/_index.md",
    encode-frontmatter(
      bookCollapseSection: true,
      title: "The " + name + " module",
      ..args.named(),
    ),
  )
}



#fn-doc("", exports.remove("diagram"), weight: 1)
#fn-doc("", exports.remove("node"), weight: 2)
#fn-doc("", exports.remove("edge"), weight: 3)
#fn-doc("", exports.remove("flexigrid"), weight: 4)

#module-doc("marks", weight: 5)
#fn-doc("marks", exports.marks.remove("test"))

#module-doc("path", weight: 6)
#fn-doc("path", exports.edges.remove("apply-edge-effects"))
#fn-doc("path", exports.paths.remove("path-effect"))
#fn-doc("path", exports.paths.remove("trim-path"))
#fn-doc("path", exports.paths.remove("trim-to-intersection"))
#for name in exports.paths.keys() {
  fn-doc("path", exports.paths.remove(name))
}





#doc("reference/shapes/", frontmatter: (title: "The shapes module", weight: 7, bookCollapseSection: true))[
  == The `shapes` module

  These are the built in @node-shapes[node shapes], usable with the @node.shape option.

  #common.shapes-gallery
]

#for name in exports.shapes.keys() {
  fn-doc("shapes", exports.shapes.remove(name))
}


#module-doc("parsing", weight: 8)

#for name in exports.parsing.keys() {
  fn-doc("parsing", exports.parsing.remove(name))
}
