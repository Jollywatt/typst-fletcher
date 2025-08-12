# Contributing to fletcher

Thank you for your interest in contributing to fletcher! This guide explains how to install Pixi, run Tytanic tests, update the README, build the manual, and edit docstrings.

## Installing Pixi

Fletcher uses [Pixi](https://pixi.sh/) to run project commands and reproducibly install development tools such as [Tytanic](https://github.com/tytanic/tytanic) for testing, [Nushell](https://www.nushell.sh) for scripting, [Typos](https://crates.io/crates/typos) and also Typst itself.

To install Pixi, run:

```sh
curl -fsSL https://pixi.sh/install.sh | bash
```

After installation, you should have access to all the development tools via `pixi run <commands>` or by activating the development environment with

```sh
pixi shell
```

which makes the tools available directly from the command line.


## Running Tytanic Tests

Fletcher uses [Tytanic](https://github.com/tytanic/tytanic) for testing. To run all the tests:

```sh
pixi run test
```

Alternatively, enter the development environment (`pixi shell`) and use `tt` (if Tytanic is not already on your system).

Using Tytanic (see the [official docs](https://tingerrr.github.io/tytanic/)):

- `tt run <test_set>` to run all tests
- `tt update <test_set>` to update test reference images
- Test sets can be specified like so:
	- All tests, e.g., `tt run`.
	- A single test, e.g., `tt run node/shapes`
	- Tests matching glob pattern, e.g., `tt run -e g:node/*`

## Updating the README

The main `README.md` file is generated from a template `README.src.md`.
To update the README, edit the template file and run
```sh
pixi run readme
```
to generate the main file. Don't edit `README.md` directly.

The template is automatically populated with two kinds of example images:

1. `docs/readme-examples/`: Short examples with light/dark modes displayed alongside the source code.
	To compile these to light and dark SVGs, use `pixi run compile examples [pattern]`.
	They are _not_ standalone Typst documents; more like snippets with a special syntax for switching between light/dark themes (see examples).
2. `docs/gallery/`: Complex examples displayed in a table of images linking to source files.
	These should be standalone documents.
	Make sure they import the correct fletcher version!
	Compile these with `pixi compile gallery [pattern]`.

The optional `[pattern]` argument is a substring to filter filenames by.


## Building the Manual

To build the manual PDF (takes a while) and exit:

```sh
pixi run compile manual
```

You can also watch for changes and continuously edit with:

```sh
pixi run manual
```

## Editing Docstrings

The manual uses [Tidy](https://typst.app/universe/package/tidy/) to parse docstrings and populate the manual.

To create a clickable reference to a documented argument of a function, use `#param[fn][arg]` (which renders as `` `arg` ``) or `#the-param[fn][arg]` (which renders as ``the `arg` option of `fn` ``).

## Additional Notes

- Please ensure all tests pass before submitting a pull request.
- Thank you! 🎈
