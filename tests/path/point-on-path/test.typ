#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: cetz, paths,

#let subpath = ((0,0,0), false, (
  ("l", (10,0,0)),
  ("l", (10,10,0)),
))
#let path = (subpath,)

#let (pos, vel, acc) = paths.point-on-path(none, path, segment: .5)
#assert.eq(pos, (5,0,0))
#assert.eq(vel, (10,0,0))

#let (pos, vel, acc) = paths.point-on-path(none, path, segment: 1)
#assert.eq(pos, (10,0,0))
#assert.eq(vel, (0,10,0))

// at end
#let (pos, vel, acc) = paths.point-on-path(none, path, segment: 2)
#assert.eq(pos, (10,10,0))
#assert.eq(vel, (0,10,0))

// beyond end
#let (pos, vel, acc) = paths.point-on-path(none, path, segment: 3)
#assert.eq(pos, (10,10,0))
