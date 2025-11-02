#import "deps.typ": cetz
#import "utils.typ"

#let DEBUG_LEVELS = (
  "grid": 3,
  "grid.coords": 1,
  "grid.lines": 2,
  "grid.cells": 3,
  "grid.xy": 10,

  "node": 4,
  "node.origin": 4,
  "node.stroke": 3,
  "node.inset": 4,
  "node.outset": 4,

  "edge.snap": 5,
  "edge.label": 5,

  "mark": 4,
  "mark.dots": 4 ,
  "mark.bands": 5,
  "mark.path": 5,
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
    if debug.split().len() > 1 {
      return debug-level(debug.split(), option, levels: levels)
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

