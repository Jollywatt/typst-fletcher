#set page(width: auto, height: auto, margin: 1em)
#import "/src/utils.typ": interp, interp-inv

#let ys = (10, 12, 14, 20, 100)

#for (t, y) in (
  (0, 10),
  (0.5, 11),
  (1, 12),
  (1.75, 13.5),
  (3, 20),
  (3.25, 40),
  (3.5, 60),
  (3.75, 80),
  (4, 100),
) {
  assert.eq(interp(ys, t), y)
  assert.eq(interp-inv(ys, y), t)
}

#for (t, y) in (
  (-2, 8),
  (-1, 9),
  (0, 10),
  (ys.len() - 1, 100),
  (ys.len(), 101),
  (ys.len() + 1, 102),
) {
  assert.eq(interp(ys, t, spacing: 1), y)
  assert.eq(interp-inv(ys, y, spacing: 1), t)
}