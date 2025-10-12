#import "@preview/tidy:0.4.3"
#import "../src/exports.typ" as fletcher
#import "common.typ": scope, example, frame

#let x-target = sys.inputs.at("x-target", default: "pdf")
#let is-md-target = x-target == "md"

#show ref: it => {
  raw("@" + str(it.target))
}

#let show-fn-docs(path, fn-name) = {
  let mod = tidy.parse-module(read(path), scope: scope)
  let fn-info = mod.functions.find(x => x.name == fn-name)

  eval(fn-info.description, mode: "markup", scope: scope)

  set raw(lang: "typc")

  for (name, arg) in fn-info.args {
    [== #raw(name)]
    show raw.where(lang: "svg"): it => frame(eval(it.text, scope: scope))
    show raw.where(lang: "example"): it => example(raw(it.text, lang: "typ"))
    eval(arg.description, mode: "markup", scope: scope)
  }

}

#if is-md-target {
  show-fn-docs(sys.inputs.path, sys.inputs.fn-name)
} else {
  // panic()
  show-fn-docs("../src/edges.typ", "edge")
}