# lilac

![workflow](https://github.com/matthewd673/lilac/actions/workflows/ruby.yml/badge.svg)

Lilac is a small compiler "middle end" written in Ruby.

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
