#import "deps.typ": cetz
#import "utils.typ"

#let DEBUG_LEVELS = (
  "grid": 1,
  "grid.coords": 1,
  "grid.lines": 2,
  "grid.cells": 2,

  "node": 2,
  "node.stroke": 2,
  "node.inset": 4,
  "node.outset": 3,

  "edge.snap": 3,

  "mark": 4,
  "mark.dots": 4 ,
  "mark.bands": 5,
  "mark.path": 5,
)

#let get-debug(ctx, debug) = {
  let d = ctx.at("fletcher-debug", default: debug)
  if d == auto { false } else { d }
}

#let suggest-option(debug) = {
  let d = ""
  let suggestions = DEBUG_LEVELS.keys().sorted(key: k => k.split(".").len())
  for char in debug.clusters() {
    let s = suggestions.filter(k => k.starts-with(d))
    
    if s.len() == 0 {
      break
    } else {
      suggestions = s
      d += char
    }
  }
  utils.error("`debug: #debug`. Options: #..0", debug: repr(debug), suggestions)
}

#let debug-level(debug, option, levels: DEBUG_LEVELS) = {
  assert(option in DEBUG_LEVELS)
  if debug == none or debug == "" { return false }
  if type(debug) == bool { return debug }
  if type(debug) == int { return levels.at(option) <= debug }
  if type(debug) == str {
    // return option.starts-with(debug) or debug.contains(option)
    if " " in debug {
      debug = debug.split(regex("\\s"))
      return debug-level(debug, option)
    }
    if debug in DEBUG_LEVELS {
      return debug.starts-with(option) or option.starts-with(debug)
    } else {
      suggest-option(debug)
    }

  }
  if type(debug) == array { return debug.any(d => debug-level(d, option)) }
  if type(debug) == dictionary {
    return debug.pairs().any(((scope, debug)) => {
      option.starts-with(scope) and debug-level(debug, option)
    })
  }
  panic(debug)
}

#assert(debug-level("grid", "grid.coords"))
#assert(debug-level("grid.coords", "grid"))
#assert(debug-level((grid: 2, node: 100), "grid.lines"))
#assert(not debug-level((grid: 1, node: 100), "grid.cells"))

#let debug-draw(debug, level, body) = {
  if not debug-level(debug, level) { return }
  cetz.draw.floating(cetz.draw.group(cetz.draw.on-layer(100, body)))
}