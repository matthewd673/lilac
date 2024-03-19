# lilac

## Build and run

Lilac uses [rbenv](https://github.com/rbenv/rbenv) to manage its Ruby version.

To build and run Lilac's (very small) CLI:

```
bundle install
rake
```

To build and use Lilac in another gem:

```
cd ~/.../lilac
gem build
cd ~/.../other_gem
gem install --local ~/.../lilac/lilac-X.X.X.gem
```
