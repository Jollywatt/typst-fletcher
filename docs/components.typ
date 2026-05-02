#import "common.typ"

#let logo = common.frame(stack(
  spacing: 12pt,
  {
    import common.fletcher: diagram, edge, node
    set text(1.3em)
    diagram(
      spacing: 25mm,
      node((0, 1), $A$),
      node((1, 1), $B$),
      edge((0, 1), (1, 1), $f$, ">>->", stroke: 1pt),
    )
  },
  move(dy: -.3em, text(3.2em, emph[fletcher])),
  [_(noun) a maker of arrows_],
))

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
  show: par
  show: it => {
    if common.is-html() {
      html.pre(it, class: "fn-signature")
    } else {
      it
    }
  }

  set text(font: "DejaVu Sans Mono", size: 0.8em)

  if fn.name in common.FUNCTION_PATHS {
    text(common.FUNCTION_PATHS.at(fn.name).join(".") + ".")
  } else {
    panic("unexported function", fn.name)
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

      if "types" in info and info.types != ("",) {
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

#let show-function-argument(fn, arg, info, level: 3) = {
  common.rich-ref(
    fn.name + "." + arg,
    entity: "argument",
    function: fn.name,
    argument: arg,
  )

  if common.is-html() {
    html.div(class: "fn-arg", {
      heading(raw(arg), level: level)

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
      box(heading(raw(arg), level: level))
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

  heading(raw(common.FUNCTION_PATHS.at(fn.name).join(".") + "." + name + "()"), level: level)

  eval(fn.description, mode: "markup", scope: common.scope)

  show-function-signature(fn)

  for (arg, info) in fn.args {
    if info.description == "" { continue }
    show-function-argument(fn, arg, info, level: level + 1)
  }
}
