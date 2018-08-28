# ruthless.io

*Version 0.4.0*

Ruthlessly simple static site generator, written in Ruby.

## Prerequisites

* [Ruby 1.9+](https://www.ruby-lang.org)
* [inifile](https://github.com/twp/inifile) - ```sudo gem install inifile```
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
  ruthless.ini
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

### Configuration

The ```site``` folder should have a ```ruthless.ini``` file with the following options (if you create a new site then this is what will be provided for you).

``` ini
[SITE]
title = Ruthless
blurb = Ruthlessly simple static site generator
```

### Basic flow

The site is rendered using your content, the ```.liquid``` template, and the ```theme.css```.

* the ```ruthless.ini``` file is read in
* The ```theme.css``` file is copied over
* Your ```.md``` files and their locations are read in
* They is passed though *Red Carpet* for fast conversion to HTML
* They are then passed through *Liquid* for fast templating
* The results are written to matching folders in the output

### Allowed properties in the template

This list is complete, though very small as *ruthless* is still in progress.
There is incoming code to load this from your ```site``` folder.

* sitetitle - from the ini file
* siteblurb - from the ini file
* content - the final output from the flow above
