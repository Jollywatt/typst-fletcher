#import "common.typ"

#let show-type(type) = {
  if common.is-html() {
    html.span(class: "type", title: type, raw(type, lang: "typc"))
  } else {
    import common.tidy.styles.default: colors
    h(2pt)
    let clr = colors.at(type, default: colors.default)
    box(outset: 2pt, fill: clr, radius: 2pt, raw(type, lang: none))
    h(2pt)
  }
}



#let show-function-signature(fn) = {
  set text(font: "DejaVu Sans Mono", size: 0.8em)

  if fn.name in common.FUNCTION_PATHS {
    text(common.FUNCTION_PATHS.at(fn.name).join(".") + ".")
  } else {
    text(red)[unexported: ]
  }

  text(fn.name, fill: common.tidy.styles.default.colors.signature-func-name)
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
        // arg-name
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
  common.rich-ref(
    fn.name + "." + arg,
    entity: "argument",
    function: fn.name,
    argument: arg,
  )

  if common.is-html() {
    html.div(class: "fn-arg", {
      [== #raw(arg)]

      html.div(class: "fn-arg-details", {
        if "types" in info {
          info.types.map(show-type).join[ or ]
        }
        if "default" in info {
          [ default ]
          raw(info.default)
        }
      })

      eval(info.description, mode: "markup", scope: common.scope)
    })
  } else {
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
        eval(info.description, mode: "markup", scope: common.scope)
      },
    )

    v(1em)
  }
}



#let show-fn(name, level: 3) = context {
  let fn = common.DOCSTRINGS.at(name)
  state("current-function").update(fn.name)

  common.rich-ref(fn.name, entity: "function", function: fn.name)

  if common.is-html() {
    [= #raw(common.FUNCTION_PATHS.at(fn.name).join(".") + "." + name + "()")]
  } else {
    heading(raw(fn.name + "()"), level: level)
    show-function-signature(fn)
  }

  eval(fn.description, mode: "markup", scope: common.scope)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    show-function-argument(fn, arg, info)
  }
}
