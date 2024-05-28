# lilac

![Build workflow](https://github.com/matthewd673/lilac/actions/workflows/build.yml/badge.svg)
![Test workflow](https://github.com/matthewd673/lilac/actions/workflows/test.yml/badge.svg)

Lilac is a small compiler infrastructure written in Ruby.

## Features

* Intermediate language (Lilac IL)
* Analyses
  * Iterative data-flow analysis framework
* Machine-independent optimizations
* Transformations
  * Convert to SSA, make CFG reducible, etc.
* Machine-dependent code generation
  * Wasm target (both Wat and Wasm binary)
    * Relooper
    * Wasm-dependent optimizations
* Interpreter for Lilac IL
* Frontend for Lilac IL
  * Available via CLI
* Debugging tools
* Validations for IL generated by third-party frontend
 
## Documentation

API docs for Lilac are available [here](https://matthewd673.github.io/lilac/). Documentation is
generated automatically with [Yard](https://yardoc.org) whenever `master` changes.

## Build and run

Lilac uses [rbenv](https://github.com/rbenv/rbenv) to manage its Ruby version.

To set up Lilac:

```
bundle install
rake
```

To build and use Lilac in another gem:

```
cd ~/.../lilac
rake
cd ~/.../other_gem
gem install --local ~/.../lilac/lilac-X.X.X.gem
```

### CLI

Lilac also has a very simple CLI that can be run with the following:
```
ruby lib/lilac.rb
```

The Lilac CLI includes tools for printing information about Lilac and parsing Lilac IL source code files.

### Tests

To run Lilac's tests:
```
rake test
```

Some of Lilac's tests require the [WebAssembly/wabt](https://github.com/webassembly/wabt) tools to be installed and accessible in `PATH`.
