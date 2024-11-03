#!/usr/bin/env nu

# This script is used to compile example diagrams in the readme and gallery.
#


const TYP_TEMPLATE = '
#import "/src/exports.typ" as fletcher: diagram, node, edge
#set page(width: auto, height: auto, margin: 1em, fill: none)
#set text(fill: white) // darkmode

// Not sure how to scale SVGs output, so just do this
#show: it => context {
	let factor = 1.8
	let m = measure(it)
	box(
		inset: (
			x: m.width/factor,
			y: m.height/factor,
		),
		scale(factor*100%, it),
	)
}

'

const EXAMPLES_PATH = "docs/readme-examples"

def apply_example_template [path, --darkmode(-d)] {
	let src = $TYP_TEMPLATE + (open $path)

	let src = if $darkmode {
		$src
	} else {
		$src | lines | filter {
			not ($in | str ends-with '// darkmode')
		} | each {
			$in | str replace --regex --all '/\*darkmode\*/.*/\*end\*/' ''
		} | str join "\n"
	}

	$src
}

def compile_example [path, --darkmode(-d)] {
	let src = apply_example_template $path --darkmode=$darkmode
	let destpath = $path | path parse |
		update stem { $"($in)-(if $darkmode {'dark'} else {'light'})" } |
		update extension svg |
		path join

	$src | save temp.typ --force
	typst compile --root . temp.typ $destpath --format svg
	rm temp.typ
}



# Compile light and dark versions of README example diagrams.
#
# For each file in /docs/readme-examples/*.typ, two images are produced:
# 1. /docs/readme-examples/*-light.svg for light backgrounds
# 2. /docs/readme-examples/*-dark.svg for dark backgrounds
def "main examples" [
		pattern: string = '' # Filter to examples with name matching regex
	] {
	# navigate to repository root
	# cd $env.FILE_PWD
	# cd ../

	ls docs/readme-examples/*.typ |
		insert basename { $in.name | path basename } |
		where basename =~ $pattern |
		each { |it|
			print -n (ansi green_bold) 'Compiling' (ansi w) $": ($it.name) " (ansi reset) "(light mode)\n"
			compile_example $it.name
			print -n (ansi green_bold) 'Compiling' (ansi w) $": ($it.name) " (ansi reset) "(dark mode)\n"
			compile_example $it.name --darkmode
		}

	null
}



# Compile gallery examples to SVGs
def "main gallery" [
	pattern : string = "" # Filter to filenames matching regex
] {
	ls docs/gallery/*.typ |
		insert parts {|it| $it.name | path parse} |
		where parts.stem =~ $pattern |
		insert dest {|it| $it.parts | update extension svg | path join } |
		each { |it|

			let src = open $it.name |
				str replace --regex '#import "@preview/fletcher:\d+.\d+.\d+' '#import "/src/exports.typ'

			$src | save temp.typ --force
			print -n (ansi green_bold) 'Compiling' (ansi w) $": ($it.name) " (ansi reset) "\n"
			typst compile --root . temp.typ $it.dest
			rm temp.typ
		}
	null
}


def main [] {
	main examples
	main gallery
}
