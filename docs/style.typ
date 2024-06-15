#import "@preview/tidy:0.2.0"

#let function-name-color = tidy.styles.default.function-name-color
#let rainbow-map = tidy.styles.default.rainbow-map
#let gradient-for-color-types = tidy.styles.default.gradient-for-color-types
#let default-type-color = tidy.styles.default.default-type-color
#let colors = tidy.styles.default.colors
#let colors-dark = tidy.styles.default.colors-dark

#let show-outline(module-doc, style-args: (:)) = box({
	let prefix = module-doc.label-prefix
	for fn in module-doc.functions [
		- #link(label(prefix + fn.name + "()"), raw(fn.name + "()"))
	]
	v(2em)
})

#let show-type(type, style-args: (:)) = {
	let c-type = if type.starts-with("pair of") {
		type.slice(8, -1)
	} else { type }
	let c = colors.at(c-type, default: colors.at("default"))
	box(outset: 2pt, fill: c, radius: 2pt, raw(type))
}


#let fn-label(fn-name) = label(fn-name + "()")
#let fn-param-label(fn-name, arg-name) = label(fn-name + "." + arg-name)




#let show-parameter-list(fn) = {
	set text(font: "Cascadia Mono", size: 0.8em, weight: 340)

	text(fn.name, fill: colors.at("signature-func-name", default: rgb("#4b69c6")))
	"("

	let inline = fn.args.len() <= 2
	if not inline { "\n  " }

	let items = fn.args.pairs().map(((arg-name, info)) => {

		if info.at("description", default: "") == "" {
			arg-name
		} else {
			link(fn-param-label(fn.name, arg-name), arg-name)
		}

		if "types" in info {
			": " + info.types.map(show-type).join(" ")
		}
	})

	items.join( if inline {", "} else { ",\n  "})
	if not inline { ",\n" } + ")"

	if fn.return-types != none {
		" -> "
		fn.return-types.map(show-type).join(" ")
	}
}



// Create a parameter description block, containing name, type, description and optionally the default value.
#let show-parameter-block(
	fn, name, types, content,
	show-default: false,
	default: none,
	fn-name: none,
	is-long: false
) = {
	let sep(it) = box(inset: (x: 5pt), text(0.8em, it))
	let type-pills = types.map(show-type).join(sep[or])
	block(
		inset: 10pt,
		breakable: is-long,
		{
			let default-multiline = type(default) == str and "\n" in default
			block(
				outset: 10pt,
				radius: 10pt,
				stroke: (top: .6pt + gray),
			)[
				#text(1em, {
						strong(raw(name))
						h(1em)
						type-pills
						if show-default and not default-multiline {
							sep[default]
							show-type(default)
						}
						h(1fr)
						text(gray, link(fn-label(fn.name), $arrow.tl$))
				})
				#fn-param-label(fn.name, name)
			]

			content

			if show-default and default-multiline [
				#parbreak()
				Default: #raw(default)
			]
		}
	)
}


#let show-function(fn, style-args) = {

	if style-args.colors == auto { style-args.colors = colors }

	block(breakable: false)[
		#text(1.2em)[
			#heading(raw(fn.name + "()"), level: style-args.first-heading-level + 1)
			#fn-label(fn.name)
		]

		#tidy.utilities.eval-docstring(fn.description, style-args)

		#show-parameter-list(fn)
	]


	for (name, info) in fn.args {
		let types = info.at("types", default: ())
		let description = info.at("description", default: "")
		if description == "" { continue }

		show-parameter-block(
			fn,
			name,
			types,
			tidy.utilities.eval-docstring(description, style-args),
			is-long: description.len() > 500, // approximate
			show-default: "default" in info and "Default:" not in description,
			default: info.at("default", default: none),
		)
	}
	v(3em, weak: true)
}



#let show-variable(
	var, style-args,
) = {
	if style-args.colors == auto { style-args.colors = colors }
	let type = if "type" not in var { none }
			else { show-type(var.type, style-args: style-args) }

	stack(dir: ltr, spacing: 1.2em,
		[
			#heading(var.name, level: style-args.first-heading-level + 1)
			#label(style-args.label-prefix + var.name)
		],
		type
	)

	eval-docstring(var.description, style-args)
	v(4.8em, weak: true)
}


#let show-reference(label, name, style-args: none) = {
	link(label, raw(name))
}

