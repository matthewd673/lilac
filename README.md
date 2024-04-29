# lilac

![workflow](https://github.com/matthewd673/lilac/actions/workflows/ruby.yml/badge.svg)

Lilac is a small compiler "middle end" written in Ruby.

## Features

* Tiny intermediate language (Lilac IL)
* Analyses
  * Compute basic blocks and CFG for IL code
  * Data-flow analysis framework
    * Dominators, live variables, reaching definitions, etc.
  * Compute dominance tree from CFG
* Machine-independent optimizations
  * Various peephole optimizations
  * LVN
* Convert arbitrary IL code to SSA form
* Machine-dependent code generation
  * Wasm target
    * Relooper
    * Wasm-dependent optimizations
    * Wat generation
* Simple interpreter for Lilac IL
* Parser and generator for Lilac IL
  * Available via CLI
* Debugging tools
  * IL pretty printer, CFG to Graphviz, etc.
 
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
