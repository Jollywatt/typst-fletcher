#import "../src/exports.typ" as fletcher
#import fletcher: diagram, edge, node
#import "../src/debug.typ": DEBUG_LEVELS
#import "@preview/tidy:0.4.3"

#let VERSION = toml("/typst.toml").package.version
#let is-html() = if "target" in std { target() == "html" } else { false }

#let frame(it) = context {
  if is-html() {
    html.div(class: "svg-frame", {
      html.frame(pad(3mm, scale(100%, reflow: true, it)))
    })
  } else {
    it
  }
}



#let scope = (
  fletcher: fletcher,
  ..dictionary(fletcher),
  frame: frame,
  shape-demo: (shape, tint) => [
    #frame(diagram(
      node((0, 0), raw(shape), shape: shape),
      node-stroke: tint,
      node-fill: tint.lighten(90%),
    ))
    #let code = {
      "node(.., shape: "
      repr(shape)
      ", "
      fletcher
        .shapes
        .NODE_SHAPES
        .at(shape)
        .pairs()
        .filter(((k, v)) => k != "draw")
        .map(((k, v)) => k + ": " + repr(v))
        .join(", ")
      ")"
    }

    #raw(code, lang: "typc")
  ],
  DEBUG_LEVELS: DEBUG_LEVELS,
)


#let example(code) = context {
  let preview = eval(code.text, mode: "markup", scope: scope)
  let code = raw(code.text, lang: "typ", block: true)

  if is-html() {
    html.div(class: "code-example", {
      html.div(class: "codeblock", code)
      frame(preview)
    })
  } else {
    grid(
      columns: (1fr, auto),
      align: horizon,
      gutter: 1em,
      code, preview,
    )
  }
}

#(scope.example = example)


#let fn-paths-by-name(mod, path: ()) = {
  let fns = (:)

  for (name, value) in dictionary(mod) {
    if type(value) == function {
      fns.insert(name, path)
    }
  }

  for (name, value) in dictionary(mod) {
    if type(value) == module {
      let s = fn-paths-by-name(value, path: (..path, name))
      for (name, path) in s {
        if name in fns {
          if path.len() < fns.at(name).len() {
            fns.at(name) = path
          }
        } else {
          fns.insert(name, path)
        }
      }
    }
  }

  return fns
}

// ordered dictionary of all functions and their shortest exported paths
// e.g., `node` has shortest path `fletcher.node` (not `fletcher.nodes.node`)
#let FUNCTION_PATHS = fn-paths-by-name(fletcher, path: ("fletcher",))


#let DOCSTRINGS = (
  (
    "../src/diagram.typ",
    "../src/flexigrid.typ",
    "../src/nodes.typ",
    "../src/edges.typ",
    "../src/paths.typ",
    "../src/marks.typ",
    "../src/shapes.typ",
    "../src/parsing.typ",
  )
    .map(path => tidy.parse-module(read(path)).functions)
    .join()
    .map(fn => (fn.name, fn))
    .to-dict()
)


#let insert-at-path(dict, path, value) = {
  if path.len() > 0 {
    let p = path.remove(0)
    dict + ((p): insert-at-path(dict.at(p, default: (:)), path, value))
  } else {
    dict.insert(value, value)
    dict
  }
}

// dictionary reflecting the entire package submodule structure
#let EXPORT_TREE = (:)
#for (name, path) in FUNCTION_PATHS {
  if name in DOCSTRINGS {
    EXPORT_TREE = insert-at-path(EXPORT_TREE, path, name)
  }
}


#let rich-ref(id, ..args) = [
  #metadata(args.named())
  #label(id)
]




#let show-ref(it) = {
  if it.element == none {
    highlight(raw(repr(it.target)))
    metadata((invalid-ref: str(it.target)))
  } else if it.element.func() == metadata and "entity" in it.element.value {
    show: link.with(it.element.location())

    if it.supplement != auto {
      // custom label text
      it.supplement
    } else {
      // format entity
      let (entity, ..info) = it.element.value
      if entity == "function" {
        raw(info.function + "()")
      } else if entity == "argument" {
        if state("current-function").get() == info.function {
          raw(info.argument)
        } else {
          raw(info.function + "." + info.argument)
        }
      } else {
        panic("unknown ref element", it.element)
      }
    }
  } else if it.element.func() == heading {
    let body = (
      if it.supplement == auto { it.element.body } else { it.supplement }
    )
    link(it.target, body)
  } else {
    panic(it)
  }
}



#let style(body) = {
  show ref: show-ref

  set raw(lang: "typc")
  show raw.where(lang: "example"): example
  show raw.where(lang: "svg"): it => frame(eval(it.text, mode: "code", scope: scope))

  body
}
