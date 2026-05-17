#let sidebar = html.nav[
	#link(<home>, html.frame[_fletcher manual_])

	- #[*Gallery*]
	- #[*Manual*]
		- #[Overview]
		- Diagrams and Layout
		- #[Nodes]
		- #link(<edges>)[Edges]
	- *Function Reference*
		- `diagram()`
		- `node()`
		- `edge()`
		#html.details[
			#html.summary[`paths` module]
			- `apply-edge-effects()`
			- `path-effect()`
		]
]

#let menu-button = html.label(..("for": "menu-control"), id: "menu-button")[
		#html.frame(stack(..(line(length: 1em, stroke: 0.5pt),)*5, spacing: 0.2em, dir: ttb))
	]

#let sitepage(body) = {
	html.link(href: "/styles.css", rel: "stylesheet")
	html.main({
		html.input(type: "checkbox", id: "menu-control")
		sidebar
		html.label(..("for": "menu-control"), class: "menu-overlay")
		html.article[
			#menu-button
			#body

		]
	})
}

#show raw.where(block: true): html.div.with(class: "codeblock")

#asset("/styles.css", read("assets/styles.css"))

#document("index.html", sitepage[
	= Heading
	#lorem(20)
]) <home>



#document("cool.html", sitepage[
	= Edges

	#lorem(200)


]) <edges>
