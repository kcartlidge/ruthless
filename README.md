# ruthless.io

*Version 0.3.0*

Ruthlessly simple static site generator, written in Ruby.

## Prerequisites

* [Ruby 1.9+](https://www.ruby-lang.org)
* [RedCarpet](https://github.com/vmg/redcarpet) - ```sudo gem install redcarpet```
* [Liquid](https://shopify.github.io/liquid/) - ```sudo gem install liquid```
* [Webrick](https://github.com/ruby/webrick) - ```sudo gem install webrick```

*Webrick is only being used for serving the static site locally.*

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
  layout.liquid
  theme.css
  content/
    index.md
    news/
      site-launch.md
      about-the-site.md
    blog/
      how-i-wrote-this-site.md
```

## Site content

### Basic flow

The site is rendered using your content, the ```.liquid``` template, and the ```theme.css```.

* The ```theme.css``` file is copied over
* Your ```.md``` file and it's location is read in
* It is passed though *Red Carpet* for fast conversion to HTML
* This is then passed through *Liquid* for fast templating
* The result is written to a matching folder in the output

### Allowed properties in the template

This list is complete, though very small as *ruthless* is still in progress.
There is incoming code to load this from your ```site``` folder.

* sitetitle - hardcoded to 'ruthless.io'
* siteblurb - hardcoded to reflect *ruthless*
* content - the final output from the flow above
