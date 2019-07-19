# Ruthless.io

Ruthlessly simple static site generator, written in Ruby.

See the [change log file](CHANGELOG.md) for current and previous version details.

## Contents

- Benefits
- Usage
- Creating a site
- Installing

---

## Benefits

- It's a **single file** - no installation needed, just drop a copy of the ```ruthless.rb``` script straight into any folder to start using it.
- You can **create a complete sample site**, including **layout** and **theme**, simply by running the script.
- Optionally generate pages that **don't need .html extentions even where the server doesn't support that option**.
- Other than Ruby and Bundler, it **bootstraps it's own dependencies** for ease of use.
- Write your content using **Markdown** or **plain text** files and they will use your **template and theme**. Other files are simply copied in unchanged.
- **Built-in server** option for local development.
- The Markdown files can have **any YAML** content you like and it will be **passed to your layout**.

---

## Usage

As *Ruthless* is a single file, the simplest option is to place a copy in the folder where you will be creating content. From there, you can do the following:

| Command | Action |
|-------- |------- |
|`ruby ruthless.rb new`|Generate a simple site in a new subfolder (always named `site`).|
|`ruby ruthless.rb build`|Render a static version of the site found in the `site` subfolder.|
|`ruby ruthless.rb serve`|Build, then serve the site in the `site` subfolder (dev only).|

The generated static site will be in a `www` folder alongside the `site` one. Any existing `www` folder will be replaced (permissions permitting).

---

## Creating a site

Content is created as [Markdown](https://daringfireball.net/projects/markdown/) files in a `content` subfolder. Your site's final built structure will mirror the `content` folder structure you employ.
Running `ruby ruthless.rb new` will create this structure for you, along with some extra files. The result is shown below:

``` text
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

``` text
site/
  content/
    news/
      latest-updates.md
    blog/
      a-site-is-born.md
```

### Configuration

The `site` folder should have a `ruthless.ini` file with the following options (if you create a new site then a sample one will be provided for you).

``` ini
[SITE]
title = Ruthless
blurb = Ruthlessly simple static site generator
footer = Created by <a href='https://ruthless.io' target='_blank'>ruthless.io</a> and <a href='https://www.ruby-lang.org' target='_blank'>Ruby</a>.
keywords = ruthless,static,site,generator

[OPTIONS]
extentions = false

[MENU]
Home = /
Latest = /news
```

### Basic flow

The site is rendered using your content, combined with the `layout.liquid` template and the `theme.css` stylesheet.

- The `ruthless.ini` file is read in
- The `theme.css` file is copied over
- Your `*.md` files and their locations are read in
- They are split into YAML front matter and Markdown content
- The Markdown is passed though *Red Carpet* for fast conversion to HTML
- The new HTML and the YAML are then passed through *Liquid* for fast templating
- The results are written to matching folders in the output
- Files named `*.txt` are also passed through *Liquid*, but are not treated as Markdown. They will be written inside `<pre>` tags.
- Other file types are copied across unchanged.

### Supported variables in the template

Some site-level variables are always available.
In addition, by using content front matter (simple YAML metadata) *you can provide any key/value information you like and it will make it's way to the template*. See the sample news item content in a newly-created site for a demo.

For example:

``` yaml
---
title: Welcome to Ruthless
dated: 2018-08-27
newsflash: This is a custom variable I can use in my layouts!
---

Lorem ipsum dolor sit amet adipiscing.
```

#### Display **site** data from the site ini file

These are the supported site-level items:

- `sitetitle` - the text to show in the title
- `siteblurb` - the text to show below the title
- `sitefooter` - the text to show in the footer area
- `sitekeywords` - the HTML metatag keywords

#### Display **content** data from an entry's YAML front matter

These are the supported entry-level items by default:

- `title` - the human readable title to show on a piece of content
- `dated` - the (text) date value to show on a piece of content
- `author` - the value to use for the author HTML metatag
- `keywords` - extra keywords to join the `sitekeywords`
- `content` - the location to inject rendered content

Other items can be placed in the YAML area and will pass through intact.

---

## Installing

### Required in advance

These will need to available on your system first:

- [Ruby 2+](https://www.ruby-lang.org) (v1.9+ should also work)
- [Bundler](https://bundler.io/)

#### Ruby 2+

You can use the main Ruby site installation details (see link above), or try [RVM, the Ruby Version Manager](https://rvm.io). On Windows the [Ruby+Devkit 2.4.X](https://rubyinstaller.org/downloads/) helps, but be sure to do the full (larger) install when prompted.

#### Bundler

Upon running *Ruthless* it will fetch it's own dependencies via *Bundler*.
For this to work, Bundler must already be available:

``` sh
sudo gem install bundler
```

### Handled automatically

Running *Ruthless* will fetch the following automatically (via Bundler) on first use:

- [inifile](https://github.com/twp/inifile)
- [RedCarpet](https://github.com/vmg/redcarpet)
- [Liquid](https://shopify.github.io/liquid/)
- [Webrick](https://github.com/ruby/webrick)

*Webrick* is used for serving the static site locally when creating/updating it, and *is not intended for use in production*.

---

## Debugging in Visual Studio Code

- Add the [Ruby extention by Peng Lv](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby)
- Install the debugging dependencies:

``` sh
gem install bundler
gem install ruby-debug-ide
gem install debase
```
