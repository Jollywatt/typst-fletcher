#import "/src/utils.typ": *

#assert(range(-500, 500).all(a => {
  let b = wrap-angle-180(a*1deg/2)
  -180deg <= b and b < 180deg
}))


// test cubic-second-derivative

#import "/src/paths.typ": cubic-second-derivative
#import "/src/deps.typ": cetz.vector, cetz.util.bezier
#import bezier: cubic-point, cubic-derivative

#let tol = 1e-6
#let h = 1e-4

#let ctrl-pts = (
  ((0,0), (1,2), (3,2), (4,0)),
  ((0,0), (3,2), (0,3), (4,0)),
  ((0,0), (2,1), (1,3), (4,0)),
)

#for c in ctrl-pts {
  for t in range(0, 100).map(t => t/100.0) {

    // approximate second derivative from first derivative
    let approx = vector.div(vector.sub(
      cubic-derivative(..c, t + h),
      cubic-derivative(..c, t - h),
    ), 2*h)
    let exact = cubic-second-derivative(..c, t)
    assert(vector.len(vector.sub(approx, exact)) < tol)

    // approximate second derivative from zeroth derivative
    let approx = vector.div(
      vector.add(
        vector.add(
          cubic-point(..c, t + h),
          vector.scale(cubic-point(..c, t), -2)
        ),
        cubic-point(..c, t - h),
      ),
      h*h,
    )
    let exact = cubic-second-derivative(..c, t)
    assert(vector.len(vector.sub(approx, exact)) < tol)

  }
}