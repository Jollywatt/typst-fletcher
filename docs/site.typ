#import "common.typ"
#import "components.typ"

#let URL_ROOT = sys.inputs.at("url-root", default: "")

#show: common.style

#let menu-tree = state("menu-tree", (:))

#let manual-pages = (
  ("intro.html", "sections/intro.typ", <manual-intro>),
  ("nodes.html", "sections/nodes.typ", <manual-nodes>),
  ("edges.html", "sections/edges.typ", <manual-edges>),
  ("marks.html", "sections/marks.typ", <manual-marks>),
  ("diagrams.html", "sections/diagrams.typ", <manual-diagrams>),
  ("cetz.html", "sections/cetz.typ", <manual-cetz>),
  ("debug.html", "sections/debug.typ", <manual-debug>),
)

#let nav-expander-script = ```js
  // A script to automatically enlarge the navbar when hovering over wide links
  const nav = document.querySelector('nav');
  const navWidth = nav.offsetWidth;
  let stretchedWidth = navWidth;

  const closeNav = () => {
    nav.classList.remove('stretched');
    nav.style.removeProperty('min-width');
    stretchedWidth = navWidth;
  }

  const expandNav = (width) => {
    if (width <= stretchedWidth) return;
    stretchedWidth = width;
    nav.classList.add('stretched')
    nav.style.minWidth = `${stretchedWidth}px`;
  }

  nav.addEventListener('mouseleave', closeNav)
  let counter = 0;
  nav.querySelectorAll('li a').forEach(item => {
    item.addEventListener('mouseenter', () => {
      const c = ++counter;
      setTimeout(() => {
        const w = item.getBoundingClientRect().right - nav.getBoundingClientRect().left;
        if (c == counter) expandNav(w + 25);
      }, 500)
    });
    item.addEventListener('mouseleave', () => {
      const c = ++counter;
      setTimeout(() => {
        if (c == counter) closeNav();
      }, 2e3);
    });
  });
```

#let dropdown(title, body, open: false) = html.details({
  html.summary(title)
  body
}, open: open)

#let sidebar = context html.nav[
  #html.div(id: "sidebar-title", link(<home>, html.frame({
    text(1.75em)[_fletcher manual_]
  })))

  - #link(<gallery>)[*Gallery*]

  - #[*Manual*]
    #for (dest, src, id) in manual-pages {
      let title = query(selector(heading).within(id)).first().body
      if id == state("current-document").get() [
        - #strong(link(id, title))
          #let headings = (query(selector(heading).within(id))
            .filter(it => it.level > 1))
          #for heading in headings {
            [- #html.elem("span", link(heading.location(), heading.body), attrs: (data-depth: str(heading.level)))]
          }
      ] else [
        - #link(id, title)
      ]
    }

  - *Function Reference*

    #let tree = menu-tree.final()
    #let (this-mod, this-fn) = state("current-fn-page", (none, none)).get()

    #let fn-link(name) = {
      let it = link(label("ref-" + name), raw(name + "()"))
      if this-fn == name { it = strong(it) }
      list.item(it)
    }

    // main functions
    #tree.remove("main").map(fn-link).join()
    // mod functions in dropdowns
    #for (mod, tree) in tree {
      dropdown(
        open: mod == this-mod,
        [#raw(mod) module],
        tree.map(fn-link).join(),
      )
    }
]

#let menu-button = html.label(..("for": "menu-control"), id: "menu-button")[
    #html.frame(stack(..(line(length: 1em, stroke: 0.5pt),)*5, spacing: 0.2em, dir: ttb))
  ]

#let page-nav = context {
  let doc-label = state("current-document", none).get()
  if doc-label == none { return }


  let i = manual-pages.position(((_, _, label)) => label == doc-label)
  if i == none { return }

  let prev = if i > 0 { manual-pages.at(i - 1).last() }
  let next = if i < manual-pages.len() - 1 { manual-pages.at(i + 1).last() }


  let icon(a) = html.frame(common.diagram(common.edge((0pt,0), (a, 1pt), " >", stroke: 1pt)))
  let nav-link(label, dir) = {
    let title = query(selector(heading).within(label)).first().body
    let body = if dir == left {icon(180deg) + html.div(title) } else { html.div(title) + icon(0deg) }
    link(label, body)
  }
  html.footer(id: "page-nav", {
    html.div(if prev != none { nav-link(prev, left) })
    html.div(if next != none { nav-link(next, right) })
  })


}

#let template(body) = {
  html.link(href: URL_ROOT + "/styles.css", rel: "stylesheet")
  html.main({ // wrap in main so inputs aren't wrapped in <p>
    html.input(type: "checkbox", id: "menu-control")
    sidebar
    html.label(..("for": "menu-control"), class: "menu-overlay")
    html.article[
      #body
      #menu-button
      #page-nav
    ]
    html.div(id: "wip-banner")
  })
  html.script(nav-expander-script.text)
}


#asset("/styles.css", read("assets/styles.css"))

#asset("/manual.pdf", read("manual.pdf", encoding: none)) <manual-pdf>

// Home page

#document("index.html", template[
  #show: html.div.with(style: "text-align: center")

  #html.div(style: "margin: 15vh 0;")[
    #box(components.logo)

    #components.package-summary

    *Version #common.VERSION*
  ]

  #link(<manual-pdf>, html.img(src: "https://img.shields.io/badge/Manual-PDF-orange"))
  #link("https://typst.app/universe/package/fletcher/", html.img(src: "https://img.shields.io/badge/Typst-Universe-239dad"))
  #link("https://github.com/Jollywatt/typst-fletcher/", html.img(src: "https://img.shields.io/badge/GitHub-Repo-blue?logo=github"))
  #link("https://forum.typst.app", html.img(src: "https://img.shields.io/badge/ask-on%20Typst%20forum-239dad"))
  #link("https://discord.com/channels/1054443721975922748/1260973351900414102", html.img(src: "https://img.shields.io/badge/ask-on%20Discord-2a4d7e"))

  This is a #highlight[largely incomplete] web version of the manual for this package.

]) <home>



// Gallery

#let gals = (
  "gallery/01-commutative.typ",
  "gallery/02-algebra-cube.typ",
  "gallery/03-ml-architecture.typ",
  // "gallery/04-io-flowchart.typ",
  "gallery/05-digraph.typ",
  // "gallery/06-node-groups.typ",
  "gallery/07-uml-diagram.typ",
  "gallery/08-tree.typ",
  "gallery/09-feynman-diagram.typ",
  "gallery/10-category-theory.typ",
)
#for gal in gals [
  #asset(gal, read(gal).replace("\t", "  ")) #label(gal)
]

#document("gallery.html", template[
  = Example Gallery

  Here you can find example diagrams made with `fletcher`.

  Click on an example to see its source code.

  #show: html.div.with(class: "frame-row")

  #let strip-setup(src) = src.split("\n").filter(line => {
    line = line.trim()
    return "@preview" not in line
  }).join("\n")

  #for gal in gals [
    #let it = eval(strip-setup(read(gal)), scope: common.scope, mode: "markup")

    #html.div(class: "gallery-example", {
      link(label(gal), html.frame(pad(1em, it)))
    })
  ]

]) <gallery>



// Manual



#for (i, (dest, src, doc-label)) in manual-pages.enumerate() {

  let doc = document("/manual/" + dest, {
    state("current-document").update(doc-label)
    template(include src)
  })

  [#doc #doc-label]

}



// Function reference

#let fn-doc(module, name, ..args) =  {
  let url = "reference/" + module + "/" + name + ".html"
  let doc-label = label("ref-" + name)
  let doc = document(url, {
    state("current-document").update(doc-label)
    state("current-fn-page").update(_ => (module, name))
    template(components.show-fn(name, level: 1))
  })
  [#doc #doc-label]

  menu-tree.update(l => {
    if module not in l { l.insert(module, ()) }
    l.at(module).push(name)
    l
  })
}

#let exports = common.EXPORT_TREE.fletcher

#fn-doc("main", exports.remove("diagram"), weight: 1)
#fn-doc("main", exports.remove("node"), weight: 2)
#fn-doc("main", exports.remove("edge"), weight: 3)
#fn-doc("main", exports.remove("flexigrid"), weight: 4)

#fn-doc("marks", exports.marks.remove("test"))

#fn-doc("path", exports.edges.remove("apply-edge-effects"))
#fn-doc("path", exports.paths.remove("path-effect"))
#fn-doc("path", exports.paths.remove("trim-path"))
#fn-doc("path", exports.paths.remove("trim-to-intersection"))
#for name in exports.paths.keys() {
  fn-doc("path", exports.paths.remove(name))
}

#for name in exports.shapes.keys() {
  fn-doc("shapes", exports.shapes.remove(name))
}

#for name in exports.parsing.keys() {
  fn-doc("parsing", exports.parsing.remove(name))
}
