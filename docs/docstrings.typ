#import "@preview/tidy:0.4.3"
#import "../src/exports.typ" as fletcher
#import "common.typ"
#show: common.style

#show ref: it => {
  raw("@" + str(it.target))
}

#let find-fn(path, fn-name) = {
  let mod = tidy.parse-module(read(path), scope: common.scope)
  let fn-info = mod.functions.find(x => x.name == fn-name)
  return fn-info
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

  if fn.name in common.FUNCTION_PATHS {
    text(common.FUNCTION_PATHS.at(fn.name).join(".") + ".")
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
    strong(raw(arg))
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
      eval(info.description, mode: "markup", scope: common.scope)
    },
  )
}


#let DOCSTRINGS = (
  {
    tidy.parse-module(read("../src/diagram.typ")).functions
    tidy.parse-module(read("../src/flexigrid.typ")).functions
    tidy.parse-module(read("../src/nodes.typ")).functions
    tidy.parse-module(read("../src/edges.typ")).functions
    tidy.parse-module(read("../src/paths.typ")).functions
    tidy.parse-module(read("../src/marks.typ")).functions
    tidy.parse-module(read("../src/shapes.typ")).functions
    tidy.parse-module(read("../src/parsing.typ")).functions
  }
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
#let exports = (:)
#for (name, path) in common.FUNCTION_PATHS {
  if name in DOCSTRINGS {
    exports = insert-at-path(exports, path, name)
  }
}
#let exports = exports.fletcher


#let show-fn(name, level: 3) = {
  let fn = DOCSTRINGS.at(name)
  state("current-function").update(fn.name)

  rich-ref(fn.name, entity: "function", function: fn.name)
  heading(raw(fn.name + "()"), level: level)

  eval(fn.description, mode: "markup", scope: common.scope)

  show-function-signature(fn)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    show-function-argument(fn, arg, info)
    v(1em)
  }
}


#show-fn("edge")
