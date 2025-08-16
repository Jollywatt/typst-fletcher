#import "deps.typ": cetz

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

  "mark": 4
)

#let get-debug(ctx, debug) = {
  ctx.at("fletcher-debug", default: debug)
}

#let debug-level(debug, option) = {
  if debug == none { return false }
  if type(debug) == bool { return debug }
  if type(debug) == int { return DEBUG_LEVELS.at(option) <= debug }
  if type(debug) == str { return option.starts-with(debug) or debug.starts-with(option) }
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