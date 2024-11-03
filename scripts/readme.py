#!/usr/bin/env python3
# Generate `/README.md` from the template, inserting code blocks and images to examples.
# Should be run from repo root.

import os
import re
import tomli
import lxml.etree as ET


README_TEMPLATE = """
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="{url}-dark.svg">
  <img src="{url}-light.svg">
</picture>

```typ
{src}
```
"""

README_PATTERN = re.compile(r"(```+)python\s*\n(.*?)\n\1", flags=re.DOTALL)
EXAMPLES_PATH = "docs/readme-examples"
COMMENTS_PATTERN = re.compile(r"// lightmode|\n.*// darkmode|/\*darkmode\*/[\s\S]*?/\*end\*/")


def get_version():
	return tomli.load(open("typst.toml", 'rb'))['package']['version']


def clean_example(example_name):
	srcpath = f"{EXAMPLES_PATH}/{example_name}.typ"
	with open(srcpath, 'r') as file:
		return re.sub(COMMENTS_PATTERN, '', file.read())


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


def build_readme():
	with open("README.src.md", 'r') as file:
		src = file.read()
		out = re.sub(README_PATTERN, lambda match: eval(match[2]), src)
		with open("README.md", 'w') as newfile:
			print("Writing README.md")
			newfile.write(out)

if __name__ == '__main__':
	build_readme()
