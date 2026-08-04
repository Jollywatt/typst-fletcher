#import "deps.typ": cetz
#import "utils.typ"

#let DEBUG_LEVELS = (
  "grid": 2,
  "grid.coords": 1,
  "grid.cells": 2,
  "grid.lines": 3,
  "grid.xy": 5,
  "grid.iters": 6,

  "node": 4,
  "node.origin": 5,
  "node.inset": 3,
  "node.body": 3,
  "node.outset": 4,
  "node.bounds": 5,
  "node.cell": 6,

  "edge.label": 5,
  "edge.snap": 5,
  "edge.snap.from": 6,
  "edge.snap.to": 6,

  "mark": 4,
  "mark.dots": 4,
)

#let stripes = {
  let t = 4pt
  tiling(size: (t, t), {
    set line(stroke: 0.25pt + red.transparentize(70%))
    place(line(angle: 45deg), dx: t / 2, dy: -t / 2)
    place(line(angle: 45deg), dx: -t / 2, dy: t / 2)
    line(angle: 45deg)
  })
}

#let DEBUG_STYLES = (
  grid: (
    cells: (
      stroke: (
        thickness: 0.25pt,
        paint: red,
      )
    ),
    lines: (
      stroke: (
        paint: red,
        thickness: 0.5pt,
        dash: "dotted",
      ),
    ),
    size: (
      stroke: (
        paint: red,
        thickness: 0.75pt,
        dash: "dotted",
      )
    ),
    iters: (
      size: 0.6em,
      fill: red,
    ),
  ),
  node: (
    cell: (
      fill: stripes,
      stroke: 0.5pt + red.transparentize(60%),
    ),
    body: (
      stroke: (
        paint: purple.transparentize(50%),
        thickness: 0.5pt,
      ),
    ),
    inset: (
      stroke: (
        paint: purple.transparentize(30%),
        thickness: 0.5pt,
        dash: (1pt, 1pt),
      ),
    ),
    outset: (
      stroke: (
        paint: green,
        thickness: 0.5pt,
        dash: (1pt, 1pt),
      ),
    ),
    bounds: (
      stroke: (
        paint: green.transparentize(50%),
        thickness: 0.5pt,
      ),
    ),
  ),
)

#let get-debug(ctx, debug) = {
  if debug != auto { return debug } // level is explicitly given
  if "fletcher" in ctx.shared-state {
    if ctx.shared-state.fletcher.pass == "layout" { return false }
    return ctx.shared-state.fletcher.at("debug", default: false)
  }
}

#let suggest-option(debug, levels) = {
  let d = ""
  let suggestions = levels.keys().sorted(key: k => k.split(".").len())
  for char in debug.clusters() {
    let s = suggestions.filter(k => k.starts-with(d))

    if s.len() == 0 {
      break
    } else {
      suggestions = s
      d += char
    }
  }
  utils.error("`debug: #debug`. Try: #..0", debug: repr(debug), suggestions)
}

/// Test whether the debug option is set high enough
/// to include a given debug option.
///
/// For example, if `option` is `"foo.bar"` and the
/// `levels` dictionary includes `("foo.bar": 10)`,
/// then this returns `true` if the `debug` option is:
/// - the constant `true`
/// - an integer at least `10`
/// - the specific string `"foo.bar"`
/// - a parent string like `"foo"`, if the corresponding
///   parent level `levels.foo` is at least `10`
/// - an array options, combined with logical or.
///
/// -> bool
#let debug-level(debug, option, levels: DEBUG_LEVELS) = {
  assert(option in levels)
  if debug == none or debug == "" { return false }

  if type(debug) == bool { return debug }

  if type(debug) == int { return levels.at(option) <= debug }

  if type(debug) == str {
    let parts = debug.split(regex("[\s,]+"))
    if parts.len() > 1 {
      return debug-level(parts, option, levels: levels)
    }
    debug = debug.trim()
    if debug in levels {
      if debug.starts-with(option) { return true }
      if option.starts-with(debug) { return levels.at(debug) >= levels.at(option) }
      return false
    } else {
      suggest-option(debug, levels)
    }
  }

  if type(debug) == array { return debug.any(d => debug-level(d, option, levels: levels)) }

  utils.error("invalid debug option: #0", repr(debug))
}

#let debug-group(body, layer: none) = {
  if layer != none { body = cetz.draw.on-layer(layer, body) }
  cetz.draw.floating(cetz.draw.group(body))
}
