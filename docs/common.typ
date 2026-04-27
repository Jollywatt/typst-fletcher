#import "../src/exports.typ" as fletcher
#import fletcher: diagram, edge, node
#import "../src/debug.typ": DEBUG_LEVELS

#let VERSION = toml("/typst.toml").package.version

#let scope = (
  fletcher: fletcher,
  ..dictionary(fletcher),
  shape-demo: (shape, tint) => [
    #diagram(
      node((0, 0), raw(shape), shape: shape),
      node-stroke: tint,
      node-fill: tint.lighten(90%),
    )
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

#let fn-paths-by-name(mod, path: ()) = {
  let fns = (:)

  // First pass: collect functions at this level
  for (name, value) in dictionary(mod) {
    if type(value) == function {
      fns.insert(name, path)
    }
  }

  // Second pass: recurse into modules
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


#let target = sys.inputs.at("target", default: none)


#let frame(it) = {
  html.frame(pad(5mm, scale(120%, reflow: true, it)))
}


#let example(code) = {
  let preview = eval(code.text, mode: "markup", scope: scope)
  if target == "html" {
    html.div(class: "code-example", {
      code
      frame(preview)
    })
  } else {
    grid(
      columns: (1fr, auto),
      align: horizon,
      gutter: 1em,
      raw(code.text, lang: "typ"), preview,
    )
  }
}


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
  body
}
