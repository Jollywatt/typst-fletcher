#!/usr/bin/env nu

const here = path self

const BASE_URL = '/typst-fletcher'

# Commands to compile, build and serve documentation site
def main [] {
  ^$here --help
}


# Compile typst docs to an html bundle in docs/website/content
#
# Currently requires a prerelease version of typst to be installed locally.
def "main compile" [
  --typst-path: path = typst # Path to typst binary supporting html,bundle features
] {
  ^$typst_path compile --features html,bundle --format bundle --root . docs/website/content.typ
}


def merge-frontmatter [] {
  let front_paths = glob "docs/website/content/**/frontmatter.md"
  print $"Merging ($front_paths | length) frontmatter files"
  for front_path in $front_paths {
    let index_path = ($front_path | path dirname | path join "_index.html")
    if ($index_path | path exists) {
      let front_content = open $front_path --raw
      let index_content = open $index_path
      $"($front_content)\n($index_content)" | save --force $index_path
      rm $front_path
    }
  }
}

def fix-links [] {
  let files = glob "docs/website/content/**/*.html"
  print $"Fixing links across ($files | length) files"
  for file in $files {
    open $file | str replace '/_index.html' '/' --all | save $file --force
  }
}

# Post process the html bundle to work with hugo
#
# Unfortunately, typst's html export isn't quite flexible enough
# for producing hugo-ready content pages, since
# 1) hugo require frontmatter yaml to be prefixed to files.
#    Instead, typst exports separate content/frontmatter files,
#    and we merge them in post with this script.
# 2) hugo changes paths ending in /_index.html to /index.html,
#    which breaks links made by typst, so we fix that with
#    naive string replacement
def "main post" [] {
  merge-frontmatter
  fix-links
}


# Build compiled docs into functional site with hugo
def "main build" [] {
  cd docs/website
  hugo build --baseURL $BASE_URL
}

# Compile and build docs site with typst and hugo
def "main deploy" [--typst-path: path = typst] {
  main compile --typst-path $typst_path
  main post
  main build
}

# Serve docs site with hugo
def "main serve" [] {
  cd docs/website
  hugo server --openBrowser
}


# Make typst and hugo watch for changes to documentation and serve site
def "main watch" [--typst-path: path = typst] {

  job spawn {|| main serve }

  job spawn {||
    while true {
      watch "docs/website/content" --debounce 500ms | first | main post
      sleep 1sec
    }
  }

  ^$typst_path watch --features html,bundle --format bundle --root . docs/website/content.typ
}
