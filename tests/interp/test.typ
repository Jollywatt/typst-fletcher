#set page(width: auto, height: auto, margin: 1em)
#import "/src/utils.typ": interp, interp-inv, uv-to-xy, xy-to-uv

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

#let test-grid = (
  u-min: 10,
  u-max: 15,
  v-min: -2,
  v-max: +2,
  col-centers: (0, 20, 50, 100, 120, 150),
  row-centers: (-5, -4, 0, +4, +5),
  col-gutter: 1,
  row-gutter: 3,
)

#for u in (..range(20), 10.2, 14.8, 15.5) {
  for v in (..range(-5, 5), 0.5, -2.2) {
    let xy = uv-to-xy(test-grid, (u, v))
    assert.eq(xy-to-uv(test-grid, xy), (u, v))
  }
}
