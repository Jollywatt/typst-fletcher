#!/usr/bin/env python3
# Generate `/README.md` from the template, inserting code blocks and images to examples.
# Should be run from repo root.

REPO_URL = "https://github.com/Jollywatt/typst-fletcher/raw/master"

import os
import re

src_template = """
#import "/src/exports.typ" as fletcher: node, edge
#let fg = {fg}
#let bg = {bg}

#set page(width: auto, height: auto, margin: 1em)
#set text(fill: fg)

// Not sure how to scale SVGs output, so just do this
#show: it => style(styles => {{
	let factor = 2
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

readme_template = """
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="{url}-dark.svg">
  <img src="{url}-light.svg">
</picture>

```typ
{src}
```
"""

comments_pattern = re.compile(r"/\*<\*/.*/\*>\*/", flags=re.DOTALL)
readme_pattern = re.compile(r"{{([a-z\-]+)}}")


def compile_example(example_name, darkmode=False):
	srcpath = f"docs/example-gallery/{example_name}.typ"
	destpath = f"docs/example-gallery/{example_name}{'-dark' if darkmode else '-light'}.svg"

	with open(srcpath, 'r') as file:
		src = file.read()

		fg, bg = ('white', 'black') if darkmode else ('black', 'white')
		src = src_template.format(src=src, fg=fg, bg=bg)

		with open("tmp.typ", 'w') as tmp:
			tmp.write(src)

		cmd = f"typst compile --root . tmp.typ {destpath} && rm tmp.typ"
		print(cmd)
		os.system(cmd)



def clean_example(example_name):
	srcpath = f"docs/example-gallery/{example_name}.typ"
	with open(srcpath, 'r') as file:
		src = file.read()
		return re.sub(comments_pattern, "", src)


def insert_md_example(match):
	example_name = match[1]
	url = f"{REPO_URL}/docs/example-gallery/{example_name}"
	return readme_template.format(
		src = clean_example(example_name),
		url = url,
	).replace('\t', ' '*2)

def build_readme():
	with open("README.template.md", 'r') as file:
		src = file.read()

		out = re.sub(readme_pattern, insert_md_example, src)

		with open("README.md", 'w') as newfile:
			print("Writing README.md")
			newfile.write(out)



def compile_all_examples():
	paths = map(os.path.splitext, os.listdir("docs/example-gallery"))
	names = [name for name, ext in paths if ext == ".typ"]

	for name in names:
		compile_example(name, darkmode=True)
		compile_example(name, darkmode=False)

if __name__ == '__main__':
	args = os.sys.argv[1:]

	if not set(args).issubset(['compile', 'build']):
		print("""Usage:
  ./build-readme.py compile
    Generate SVGs for all examples in /docs/example-gallery/*.typ
  ./build-readme.py build
    Generate README.md from template
  ./build-readme.py compile build
    Do both of the above
		""")

	if 'compile' in args:
		compile_all_examples()
	if 'build' in args:
		build_readme()