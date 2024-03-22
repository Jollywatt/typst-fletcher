#!/usr/bin/env python3
# Generate `/README.md` from the template, inserting code blocks and images to examples.
# Compiles both light- and dark-mode versions of the examples.
# Should be run from repo root.

REPO_URL = "https://github.com/Jollywatt/typst-fletcher/raw/master"

import os
import re
import tomllib

src_template = """
#import "/src/exports.typ" as fletcher: node, edge
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
README_PATTERN = re.compile(r"{{([a-z\-]+)}}")

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

		src = src_template.format(src=src, fg=fg, bg=bg)

		with open("tmp.typ", 'w') as tmp:
			tmp.write(src)

		cmd = f"typst compile --root . tmp.typ {destpath} && rm tmp.typ"
		print(cmd)
		os.system(cmd)


def clean_example(example_name):
	srcpath = f"{EXAMPLES_PATH}/{example_name}.typ"
	with open(srcpath, 'r') as file:
		return re.sub(COMMENTS_PATTERN, "", file.read())


def insert_md_example(match):
	example_name = match[1]
	url = f"{REPO_URL}/{EXAMPLES_PATH}/{example_name}"
	return README_TEMPLATE.format(
		src = clean_example(example_name),
		url = url,
	).replace('\t', ' '*2)

def get_version():
	return tomllib.load(open("typst.toml", 'rb'))['package']['version']

def build_readme():
	with open("README.template.md", 'r') as file:
		src = file.read().replace("{{VERSION}}", get_version())
		out = re.sub(README_PATTERN, insert_md_example, src)
		with open("README.md", 'w') as newfile:
			print("Writing README.md")
			newfile.write(out)


def compile_all_examples():
	paths = map(os.path.splitext, os.listdir(EXAMPLES_PATH))
	names = [name for name, ext in paths if ext == ".typ"]

	for name in names:
		compile_example(name, darkmode=True)
		compile_example(name, darkmode=False)

if __name__ == '__main__':
	args = os.sys.argv[1:]

	if len(args) == 0:
		args = ['compile', 'build']

	if not set(args).issubset(['compile', 'build']):
		print(f"""Usage:
		  ./build-readme.py compile
		    Generate SVGs for all examples in {EXAMPLES_PATH}/*.typ
		  ./build-readme.py build
		    Generate README.md from template
		  ./build-readme.py compile build
		    Do both of the above
		""")

	if 'compile' in args:
		compile_all_examples()
	if 'build' in args:
		build_readme()