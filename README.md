# ruthless.io

*Version 0.5.0*

Ruthlessly simple static site generator, written in Ruby.

* See [the ruthless website](https://ruthless.io) for details on how to create your own site (some briefer details appear below).
* See the [changelog](https://github.com/kcartlidge/ruthless/blob/master/CHANGELOG.md) for a version history.

---

## Prerequisites

* [Ruby 1.9+](https://www.ruby-lang.org)
* [inifile](https://github.com/twp/inifile) - ```sudo gem install inifile```
* [RedCarpet](https://github.com/vmg/redcarpet) - ```sudo gem install redcarpet```
* [Liquid](https://shopify.github.io/liquid/) - ```sudo gem install liquid```
* [Webrick](https://github.com/ruby/webrick) - ```sudo gem install webrick```

*Webrick is used for serving the static site locally when creating/updating it, not for production delivery of the result.*

## Installing Ruby

You can use the main Ruby site (see link above) installation details, or try [RVM, the Ruby Version Manager](https://rvm.io).

## Usage

* Ensure you have the prerequisites installed (see above).
* Create a folder and drop the ```ruthless.rb``` script into it.
* Run ```ruby ruthless.rb --site``` to generate a stub site (in a new folder named ```site```).
* Run ```ruby ruthless.rb``` to render the static version.
  * Or run ```ruby ruthless.rb --serve``` to also serve the created static site.
* The site will be created in a new ```www``` folder alongside the ```site``` one.

*Any existing ```www``` folder will be replaced (permissions permitting).*

## Site folder structure

Content is written in [Markdown](https://daringfireball.net/projects/markdown/) files, in a ```content``` folder within which your site structure is created.

Running with the ```--site``` option will create the structure for you (with the files below).

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

You can add more content like so:

```
site/
  content/
    news/
      site-launch.md
      about-the-site.md
    blog/
      how-i-wrote-this-site.md
```

## Creating site content

Run with the ```--site``` option to create your initial structure, or manually create it as shown above.

### Configuration

The ```site``` folder should have a ```ruthless.ini``` file with the following options (if you create a new site then a sample one will be provided for you).

``` ini
[SITE]
title = Ruthless
blurb = Ruthlessly simple static site generator
```

### Basic flow

The site is rendered using your content, combined with the ```layout.liquid``` template, and the ```theme.css```.

* The ```ruthless.ini``` file is read in
* The ```theme.css``` file is copied over
* Your ```*.md``` files and their locations are read in
* They are passed though *Red Carpet* for fast conversion to HTML
* They are then passed through *Liquid* for fast templating
* The results are written to matching folders in the output
* Files named ```*.txt``` are also passed through *Liquid*, but are not treated as Markdown. They will be written inside ```<pre>``` tags.
* Other file types are copied across unchanged.

### Allowed properties in the template

This list is complete, though very small as *ruthless* is still in progress.

* ```sitetitle``` - from the ```ruthless.ini``` file
* ```siteblurb``` - from the ```ruthless.ini``` file
* ```content``` - the final output from the flow above
