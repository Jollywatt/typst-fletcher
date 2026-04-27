#import "common.typ"
#show: common.style

#let fn-name = sys.inputs.fn-name

#let show-function-signature(fn) = {
  show: html.pre

  text(common.FUNCTION_PATHS.at(fn.name).join(".") + ".")

  text(fn.name)
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
        ": " + info.types.join(" | ")
      }
    })

  items.join(if inline { ", " } else { ",\n  " })
  if not inline { ",\n" } + ")"

  if fn.return-types != none {
    " -> "
    fn.return-types.join(" ")
  }
}

#let show-function-argument(fn, arg, info) = {
  let first-line = {
    [#heading(raw(arg), level: 2) #label(fn.name + "." + arg)]
    if "types" in info {
      info.types.join(text(0.8em)[ or ])
    }
    if "default" in info {
      text(0.8em)[ default ]
      raw(info.default)
    }
    // link(label(fn.name), text(gray, $arrow.tl$))
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

#let show-fn(name, level: 3) = {
  let fn = common.DOCSTRINGS.at(name)

  heading[Function #raw(fn.name + "()")]

  eval(fn.description, mode: "markup", scope: common.scope)

  show-function-signature(fn)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    show-function-argument(fn, arg, info)
    v(1em)
  }
}

#show-fn(fn-name)
