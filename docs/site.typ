#import "common.typ"
#import "components.typ"

#show: common.style

#let menu-tree = state("menu-tree", (:))

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
        if (c == counter) expandNav(item.offsetWidth + 40);
      }, 500)
    });
    item.addEventListener('mouseleave', () => {
      const c = ++counter;
      setTimeout(() => {
        if (c == counter) closeNav();
      }, 2e3);
    });
  });

  // open nav menu on hover - maybe too annoying?
  const navButton = document.getElementById('menu-button');
  const navControl = document.getElementById('menu-control');
  navButton.addEventListener('mouseenter', () => {
    navControl.checked ^= true;
  })
```

#let dropdown(title, body, open: false) = html.details({
  html.summary(title)
  body
}, open: open)

#let sidebar = context html.nav[
  #link(<home>, html.frame(pad(bottom: 5pt, text(1.6em)[_fletcher manual_])))

  - #[*Gallery*]
  - #[*Manual*]
    - #link(<manual-intro>)[Overview]
    - #link(<manual-diagrams>)[Diagrams and Layout]
    - #link(<manual-nodes>)[Nodes]
    - #link(<manual-edges>)[Edges]
    - #link(<manual-marks>)[Marks and Arrows]
    - #link(<manual-cetz>)[CeTZ Integration]

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

#let template(body) = {
  html.link(href: "/styles.css", rel: "stylesheet")
  html.main({ // wrap in main so inputs aren't wrapped in <p>
    html.input(type: "checkbox", id: "menu-control")
    sidebar
    html.label(..("for": "menu-control"), class: "menu-overlay")
    html.article[
      #menu-button
      #body

    ]
  })
  html.script(nav-expander-script.text)
}


#asset("/styles.css", read("assets/styles.css"))

#document("index.html", template[
  #show: html.div.with(style: "text-align: center")

  #html.div(style: "margin: 15vh 0;")[
    #box(components.logo)

    A #link("https://typst.app/")[Typst] package for diagrams with lots of arrows,
    built on top of #link("https://cetz-package.github.io")[CeTZ].

    *Version #common.VERSION*
  ]

  #link("manual.pdf", html.img(src: "https://img.shields.io/badge/Manual-PDF-orange"))
  #link("https://typst.app/universe/package/fletcher/", html.img(src: "https://img.shields.io/badge/Typst-Universe-239dad"))
  #link("https://github.com/Jollywatt/typst-fletcher/", html.img(src: "https://img.shields.io/badge/GitHub-Repo-blue?logo=github"))
  #link("https://forum.typst.app", html.img(src: "https://img.shields.io/badge/ask-on%20Typst%20forum-239dad"))
  #link("https://discord.com/channels/1054443721975922748/1260973351900414102", html.img(src: "https://img.shields.io/badge/ask-on%20Discord-2a4d7e"))

  This is a #highlight[largely incomplete] web version of the manual for this package.

]) <home>



// Manual

#document("intro.html", template(include "sections/intro.typ")) <manual-intro>
#document("diagrams.html", template(include "sections/diagrams.typ")) <manual-diagrams>
#document("nodes.html", template(include "sections/nodes.typ")) <manual-nodes>
#document("edges.html", template(include "sections/edges.typ")) <manual-edges>
#document("marks.html", template(include "sections/marks.typ")) <manual-marks>
#document("cetz.html", template(include "sections/cetz.typ")) <manual-cetz>


// Function reference


#let fn-doc(module, name, ..args) =  {
  let url = "reference/" + module + "/" + name + ".html"
  let doc = document(url, {
    state("current-fn-page").update(_ => (module, name))
    template(components.show-fn(name, level: 1))
  })
  [#doc #label("ref-" + name)]

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
