#import "common.typ"
#show: common.style

#let fn-name = sys.inputs.fn-name

= Function reference: #raw(fn-name)

#common.show-fn(fn-name)
