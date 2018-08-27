# ruthless.io

*Version 0.1.0*

Ruthlessly simple static site generator, written in Ruby.

## Prerequisites

* [Ruby 1.9+](https://www.ruby-lang.org)
* [RedCarpet](https://github.com/vmg/redcarpet) - ```sudo gem install redcarpet```

## Installing Ruby

You can use the main Ruby site (see link above) installation details, or try [RVM, the Ruby Version Manager](https://rvm.io).

``` sh
\curl -sSL https://get.rvm.io | bash -s stable
```

## Usage

* Ensure you have the prerequisites installed.
* Drop the ```ruthless.rb``` script into a folder.
* Run ```ruby ruthless.rb --site``` to generate a stub site.
* Run ```ruby ruthless.rb``` to render the static version.

## Site structure

Content is written in [Markdown](https://daringfireball.net/projects/markdown/) files, in a ```content``` folder within which your site structure is created.

Running with the ```--site``` option will create the structure for you.

```
ruthless.rb
site/
  content/
    index.md
    news/
      site-launch.md
      about-the-site.md
    blog/
      how-i-wrote-this-site.md
```

## Site content

There is no templating in place yet. Currently your Markdown has no recourse to shared headers/footers and/or style sheets. This is incoming.
