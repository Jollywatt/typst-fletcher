#import "@preview/tidy:0.4.3"
#import "../src/exports.typ" as fletcher
#import "common.typ"
#show: common.style

#let x-target = sys.inputs.at("x-target", default: "pdf")
#let is-md-target = x-target == "md"

#show ref: it => {
  raw("@" + str(it.target))
}

#let show-fn-docs(path, fn-name) = {

  let mod = tidy.parse-module(read(path), scope: common.scope)
  let fn-infos = mod.functions.filter(x => fn-name in x.name)

  for fn-info in fn-infos {
    [= #raw(fn-info.name + "()")]

    eval(fn-info.description, mode: "markup", scope: common.scope)

    set raw(lang: "typc")

    for (name, arg) in fn-info.args {
      [== #raw(name)]
      show raw.where(lang: "svg"): it => common.frame(eval(it.text, scope: common.scope))
      show raw.where(lang: "example"): it => common.example(raw(it.text, lang: "typ", block: true))
      eval(arg.description, mode: "markup", scope: common.scope)
    }
  }

}

#if is-md-target {
  show-fn-docs(sys.inputs.path, sys.inputs.fn-name)
} else {
  show-fn-docs("../src/shapes.typ", "cy")
}