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


#doc("docs/gallery/", frontmatter: (
  title: "Gallery",
  weight: 1,
  bookFlatSection: true,
))[
  = Gallery!
]


#asset(
  "docs/manual/_index.md",
  encode-frontmatter(
    weight: 1,
    bookFlatSection: true,
    bookCollapseSection: false,
    title: "Manual",
  ),
)


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
  #doc("docs/manual/sections/" + file, body, frontmatter: (
    title: name,
    weight: i + 1,
  ))
]


#asset(
  "docs/reference/_index.md",
  encode-frontmatter(
    weight: 2,
    bookFlatSection: true,
    bookCollapseSection: false,
    title: "Reference",
  ),
)


#let fn-doc(modules, name, ..args) = context {
  doc("docs/reference/" + modules + "/" + name, components.show-fn(name), frontmatter: (title: name, ..args.named()))
}

#let exports = common.EXPORT_TREE.fletcher

#let module-doc(name, ..args) = {
  asset(
    "docs/reference/" + name + "/_index.md",
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





#doc("docs/reference/shapes/", frontmatter: (title: "The shapes module", weight: 7, bookCollapseSection: true))[
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


#doc("", frontmatter: (title: "Fletcher"))[
  #html.div(class: "book-hero")[
    #components.logo
  ]

  #link("https://typst.app/universe/package/fletcher/", html.img(src: "https://img.shields.io/badge/Typst-Universe-239dad"))


]

// #asset("_index.md", ```md
// ---
// title: ""
// layout: landing
// ---

// <div class="book-hero">

// # fletcher {anchor=false}

// [{{< badge style="info" title="Hugo" value="0.158" >}}](https://github.com/gohugoio/hugo/releases/tag/v0.158.0)
// [{{< badge style="default" title="License" value="MIT" >}}](https://github.com/alex-shpak/hugo-book/blob/main/LICENSE)

// {{<button href="/docs/gallery/">}}Gallery{{</button>}}
// {{<button href="/docs/manual/">}}Manual{{</button>}}
// {{<button href="/docs/reference/">}}Function Reference{{</button>}}

// </div>

// {{% columns %}}

// - ## What Hugo-Book Theme Is
//     Hugo book theme is primarily designed to create technical documentation sites that are easy to read, write, navigate and maintain. It is an attempt to create a sustainable web project.

// {{% /columns %}}

// {{% columns %}}

// - {{< card >}}

//     ## Probably fast

//     Build on Hugo static site generator. "The world’s fastest framework for building websites".
//     {{< /card >}}

// - {{< card >}}

//     ## 50% JS free

//     All important features are working even with JavaScript disabled in browser, including interactive shortcodes.
//     {{< /card >}}

// {{% /columns %}}

// ```.text)
