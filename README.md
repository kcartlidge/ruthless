# Ruthless.io

**Version 1.0.1**

Ruthlessly simple static site generator, written in Ruby.

* See the [changelog](https://github.com/kcartlidge/ruthless/blob/master/CHANGELOG.md) for a version history.

---

## Installing

### Required in advance

These will need to available on your system first:

* [Ruby 2+](https://www.ruby-lang.org) (v1.9+ should also work)
* [Bundler](https://bundler.io/)

**Ruby 2+**

You can use the main Ruby site installation details (see link above), or try [RVM, the Ruby Version Manager](https://rvm.io). On Windows the [Ruby+Devkit 2.4.X](https://rubyinstaller.org/downloads/) helps, but be sure to do the full (larger) install when prompted.

**Bundler**

Upon running, *Ruthless* will fetch it's own dependencies via *Bundler*.
For this to work, Bundler must already be available:

``` sh
gem install bundler
```

### Handled automatically

Running *Ruthless* will fetch the following automatically (via Bundler) on first use:

* [inifile](https://github.com/twp/inifile)
* [RedCarpet](https://github.com/vmg/redcarpet)
* [Liquid](https://shopify.github.io/liquid/)
* [Webrick](https://github.com/ruby/webrick)

Webrick is used for serving the static site locally when creating/updating it, and is not intended for use in production.

## Usage

As *Ruthless* is a single file, the simplest option is to place a copy in the folder where you will be creating content. From there, you can do the following:

| Command | Action |
|-------- |------- |
|```ruby ruthless.rb --site```|Generate a simple site in a new subfolder (always named ```site```).|
|```ruby ruthless.rb```|Render a static version of the site found in the ```site``` subfolder.|
|```ruby ruthless.rb --serve```|Serve the site in the ```site``` subfolder (dev only).|

The generated static site will be in a ```www``` folder alongside the ```site``` one. Any existing ```www``` folder will be replaced (permissions permitting).

## Site folder structure

Content is created as [Markdown](https://daringfireball.net/projects/markdown/) files in a ```content``` subfolder. Your site's final built structure will mirror the ```content``` folder structure you employ.
Running ```ruby ruthless.rb --site``` will create this structure for you, along with some extra files. The result is shown below:

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
      latest-updates.md
    blog/
      a-site-is-born.md
```

### Configuration

The ```site``` folder should have a ```ruthless.ini``` file with the following options (if you create a new site then a sample one will be provided for you).

``` ini
[SITE]
title = Ruthless
blurb = Ruthlessly simple static site generator
footer = Created by <a href='https://ruthless.io' target='_blank'>ruthless.io</a> and <a href='https://www.ruby-lang.org' target='_blank'>Ruby</a>.

[OPTIONS]
extentions = false

[MENU]
Home = /
Latest = /news
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

#### Site

* ```sitetitle``` - from the ```ruthless.ini``` file
* ```siteblurb``` - from the ```ruthless.ini``` file
* ```sitefooter``` - from the ```ruthless.ini``` file
* ```content``` - the final output from the flow above

#### Content

By using content front matter (as flat YAML metadata) *you can provide any key/value information you like and it will make it's way to the template*, with the exception of the ones above which are built in and hence reserved.

For example:

``` yaml
---
title: Welcome to Ruthless
dated: 2018-08-27
---

For more information, see [the web site](https://ruthless.io).
```

---

## Debugging in Visual Studio Code

* Add the [Ruby extention by Peng Lv](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby)
* Install the debugging dependencies:
``` sh
gem install bundler
gem install ruby-debug-ide
gem install debase
```
