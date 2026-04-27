#import "../src/exports.typ" as fletcher
#import fletcher: diagram, edge, node
#import "../src/debug.typ": DEBUG_LEVELS
#import "@preview/tidy:0.4.3"

#let VERSION = toml("/typst.toml").package.version
#let is-html = sys.inputs.at("target", default: none) == "html"

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
#let FUNCTION_PATHS = fn-paths-by-name(fletcher)


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



#let show-type(type) = {
  import tidy.styles.default: colors
  h(2pt)
  let clr = colors.at(type, default: colors.default)
  box(outset: 2pt, fill: clr, radius: 2pt, raw(type, lang: none))
  h(2pt)
}


#let rich-ref(id, ..args) = [
  #metadata(args.named())
  #label(id)
]


#let show-function-signature(fn) = {
  show: par
  set text(font: "DejaVu Sans Mono", size: 0.8em)

  if fn.name in FUNCTION_PATHS {
    text(FUNCTION_PATHS.at(fn.name).join(".") + ".")
  } else {
    text(red)[unexported: ]
  }

  text(fn.name, fill: tidy.styles.default.colors.signature-func-name)
  "("

  let inline = fn.args.len() <= 2
  if not inline { "\n  " }

  let items = fn
    .args
    .pairs()
    .map(((arg-name, info)) => {
      if info.at("description", default: "") == "" {
        arg-name
      } else {
        link(label(fn.name + "." + arg-name), arg-name)
      }

      if "types" in info {
        ": " + info.types.map(show-type).join(" ")
      }
    })

  items.join(if inline { ", " } else { ",\n  " })
  if not inline { ",\n" } + ")"

  if fn.return-types != none {
    " -> "
    fn.return-types.map(show-type).join(" ")
  }
}

#let show-function-argument(fn, arg, info) = {
  rich-ref(
    fn.name + "." + arg,
    entity: "argument",
    function: fn.name,
    argument: arg,
  )

  let first-line = {
    box(heading(raw(arg), level: 3))
    if "types" in info {
      h(0.5em)
      info.types.map(show-type).join(text(0.8em)[ or ])
    }
    if "default" in info {
      text(0.8em)[ default ]
      raw(info.default)
    }
    h(1fr)
    link(label(fn.name), text(gray, $arrow.tl$))
  }

  let is-long = info.description.len() > 500
  block(
    inset: 10pt,
    breakable: is-long,
    {
      block(
        outset: 10pt,
        width: 100%,
        radius: 10pt,
        stroke: (top: .6pt + gray),
        first-line,
      )
      eval(info.description, mode: "markup", scope: scope)
    },
  )
}



#let show-fn(name, level: 3) = {
  let fn = DOCSTRINGS.at(name)
  state("current-function").update(fn.name)

  rich-ref(fn.name, entity: "function", function: fn.name)
  heading(raw(fn.name + "()"), level: level)

  eval(fn.description, mode: "markup", scope: scope)

  show-function-signature(fn)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    show-function-argument(fn, arg, info)
    v(1em)
  }
}





#let frame(it) = {
  html.div(class: "svg-frame", {
    html.frame(pad(5mm, scale(120%, reflow: true, it)))
  })
}


#let example(code) = {
  let preview = eval(code.text, mode: "markup", scope: scope)

  if is-html {
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


#let show-ref(it) = {
  if is-html {
    // return strong[LINK<#it.element>]
  }

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

  show raw.where(lang: "svg"): it => html.div(class: "svg-figure", frame(eval(it.text, mode: "code", scope: scope)))

  body
}
