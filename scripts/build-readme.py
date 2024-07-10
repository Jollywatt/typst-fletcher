#!/usr/bin/env python3
# Generate `/README.md` from the template, inserting code blocks and images to examples.
# Compiles both light- and dark-mode versions of the examples.
# Should be run from repo root.

import os
import re
import tomli
import lxml.etree as ET


TYP_TEMPLATE = """
#import "/src/exports.typ" as fletcher: diagram, node, edge
#let fg = {fg} // foreground color
#let bg = {bg} // background color

#set page(width: auto, height: auto, margin: 1em)
#set text(fill: fg)

// Not sure how to scale SVGs output, so just do this
#show: it => style(styles => {{
	let factor = 1.8
	let m = measure(it, styles)
	box(
		inset: (
			x: m.width/factor,
			y: m.height/factor,
		),
		scale(factor*100%, it),
	)
}})

{src}
"""

README_TEMPLATE = """
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="{url}-dark.svg">
  <img src="{url}-light.svg">
</picture>

```typ
{src}
```
"""

COMMENTS_PATTERN = re.compile(r"/\*<\*/.*?/\*>\*/|[^\n]*// hide[^\n]*\n", flags=re.DOTALL)
README_PATTERN = re.compile(r"(```+)python\s*\n(.*?)\n\1", flags=re.DOTALL)

EXAMPLES_PATH = "docs/readme-examples"


def compile_example(example_name, darkmode=False):
	srcpath = f"{EXAMPLES_PATH}/{example_name}.typ"
	destpath = f"{EXAMPLES_PATH}/{example_name}{'-dark' if darkmode else '-light'}.svg"

	with open(srcpath, 'r') as file:
		src = file.read()

		fg, bg = ('white', 'black') if darkmode else ('black', 'white')

		# light mode version should compile as seen in readme, with theme code removed
		if not darkmode:
			src = re.sub(COMMENTS_PATTERN, "", src)

		src = TYP_TEMPLATE.format(src=src, fg=fg, bg=bg)

		with open("tmp.typ", 'w') as tmp:
			tmp.write(src)

		cmd = f"typst compile --root . tmp.typ {destpath} && rm tmp.typ"
		print(cmd)
		os.system(cmd)


def compile_examples(pattern=''):
	paths = map(os.path.splitext, os.listdir(EXAMPLES_PATH))
	names = [name for name, ext in paths if ext == ".typ"]

	for name in names:
		if not pattern in name: continue
		compile_example(name, darkmode=True)
		compile_example(name, darkmode=False)


def clean_example(example_name):
	srcpath = f"{EXAMPLES_PATH}/{example_name}.typ"
	with open(srcpath, 'r') as file:
		return re.sub(COMMENTS_PATTERN, "", file.read())


def insert_example_block(example_name):
	url = f"{EXAMPLES_PATH}/{example_name}"
	return README_TEMPLATE.format(
		src = clean_example(example_name),
		url = url,
	).replace('\t', ' '*2)


def insert_example_table(items):
	table = ET.Element("table")
	i = cols = 2
	for item in items:
		if i >= cols:
			tr = ET.SubElement(table, "tr")
			i = 0
		td = ET.SubElement(tr, "td", style="background: white;")
		a = ET.SubElement(td, "a", href=f"docs/gallery/{item}.typ")
		ET.SubElement(ET.SubElement(a, "center"), "img", src=f"docs/gallery/{item}.svg", width="100%")
		i += 1
	return ET.tostring(table, encoding="unicode", pretty_print=True)

def get_version():
	return tomli.load(open("typst.toml", 'rb'))['package']['version']

def build_readme():

	with open("README.src.md", 'r') as file:
		src = file.read()
		out = re.sub(README_PATTERN, lambda match: eval(match[2]), src)
		with open("README.md", 'w') as newfile:
			print("Writing README.md")
			newfile.write(out)

USAGE = f"""
USAGE:
	build
		Create README.md from README.src.md
	compile [pattern]
		Generate light and dark themed SVGs for examples in {EXAMPLES_PATH} matching pattern
"""

if __name__ == '__main__':
	args = os.sys.argv[1:]


	if not 1 <= len(args) <= 2: exit(print(USAGE))

	if args[0] == "compile":
		if len(args) == 2:
			compile_examples(args[1])
		else:
			compile_examples()
	elif args[0] == "build":
		build_readme()
	else:
		print(USAGE)
