#set page(width: auto, height: auto, margin: 1em)
#import "/src/exports.typ" as fletcher: paths, cetz

#cetz.canvas({
  let (s, c1, c2, e) = ((0,0), (0,1), (1,-1), (2,0))
  cetz.draw.bezier(s, e, c1, c2)
  let N = 8
  for i in range(N) {
    let t0 = i/(N - 0.5)
    let t1 = t0 + 0.5/(N - 0.5)
    let (S, C1, C2, E) = paths.clamp-cubic-bezier(s, c1, c2, e, t0, t1)
    cetz.draw.bezier(S, E, C1, C2, stroke: red)
  }
})
