#set page(width: auto, height: auto, margin: 1em)
#import "/src/debug.typ": debug-level

#let l = (
  a: 1,
  b: 2,
  c: 1,
  "c.d": 1,
  "c.e": 3,
  "c.f": 2,
  "c.f.g": 2,
  "c.f.h": 4,
)

// int config
#assert(debug-level(1, "a", levels: l))
#assert(not debug-level(1, "b", levels: l))
#assert(debug-level(3, "b", levels: l))
#assert(debug-level(1, "c.d", levels: l))

// str config
#assert(debug-level("c", "c.f", levels: l))
#assert(debug-level("c.f", "c.f", levels: l))
#assert(debug-level("c.f.g", "c.f", levels: l))

#assert(debug-level("a b c", "c.f", levels: l))
#assert(not debug-level("a b c.e", "c.f", levels: l))
#assert(debug-level("a b c.f.g", "c.f", levels: l))

// array config
#assert(debug-level(("a", "b"), "a", levels: l))
#assert(debug-level(("a", "b"), "b", levels: l))
#assert(debug-level(("a", "c"), "c.f", levels: l))