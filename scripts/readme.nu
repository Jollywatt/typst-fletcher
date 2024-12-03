#!/usr/bin/env nu

# Generate README.md from template file README.src.md.
# Inserts version number, readme examples and gallery

def get_version [] {
	open typst.toml | get package.version
}

const README_EXAMPLE = '
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="{url}-dark.svg">
  <img src="{url}-light.svg">
</picture>

```typ
{src}
```
'

def clean_readme_example [path: path] {
	let parts = $path | path parse
	$README_EXAMPLE |
		str replace -a '{url}' $"($parts.parent)/($parts.stem)" |
		str replace '{src}' (open $path) |
		str replace -ra '.*//\s*darkmode\s*\n' '' |
		str replace -ra '/\*darkmode\*/[\s\S]*/\*end\*/' ''
}

def examples [] {
	ls docs/readme-examples/*.typ | get name | each {|it|
		clean_readme_example $it
	} | str join
}

def gallery [] {
	let cells = ls docs/gallery/*.typ | each {|it|
		let img = $it.name | path parse | update extension svg | path join
		{tag: td, attributes: {style: 'background: white;'} content: [{
			tag: a
			attributes: {href: $it.name}
			content: [{tag: center, content: [{
				tag: img
				attributes: {src: $img width: '100%'}
			}]}]
		}]}
	}
	let N = $cells | length
	let cols = 2
	let rows = 0..($N / $cols - 1 | math ceil) | each {|n|
		let row = $n * $cols
		{
			tag: tr
			content: ($cells | range $row..($row + $cols - 1))
		}
	}
	{tag: table, content: $rows} | to xml --indent 2 --self-closed
}

def main [] {
	open README.src.md |
		str replace -a '{VERSION}' (get_version) |
		str replace '{README_EXAMPLES}' (examples) |
		str replace '{GALLERY}' (gallery) |
		save README.md --force
	print "Wrote to README.md"
}
