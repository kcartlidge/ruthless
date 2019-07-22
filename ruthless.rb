#!/usr/bin/ruby

version = "2.0.1"
puts "(ensuring dependencies - slower first time)"

require "fileutils"
require "find"
require "set"
require "bundler/inline"
gemfile do
  source "https://rubygems.org"
  gem "inifile"
  gem "kramdown"
  gem "liquid"
  gem "webrick"
end

# Show the intro.
puts
puts "RUTHLESS #{version}  https://ruthless.io"
puts "Ruthlessly simple static site generator"
puts
puts "ruby ruthless.rb <command>"
puts "  new     Create a new site"
puts "  build   Generate the site output"
puts "  serve   Build and serve the site"
puts
puts 'The site should be in a "site" subfolder'
puts 'Builds are written to a sibling "www" folder'
puts

# Define folder/file locations.
@site_folder = File.join(File.dirname(__FILE__), "site")
@html_folder = File.join(File.dirname(__FILE__), "www")
@content_folder = File.join(@site_folder, "content")
@layouts_folder = File.join(@site_folder, "theme")
@includes_folder = File.join(@layouts_folder, "includes")
@sample_news_folder = File.join(@content_folder, "news")
@ini_file = File.join(@site_folder, "ruthless.ini")
@layout_file = File.join(@layouts_folder, "layout.liquid")
@theme_file = File.join(@layouts_folder, "theme.css")

# Define some options.
@templatable = [".md", ".txt"].to_set
@menu = []

# Display the error message then abort.
def fatal(message)
  puts "-------------------------------------------"
  puts "ERROR: #{message}"
  abort
end

# Display the message then exit.
def done(message)
  puts message
  exit
end

# Create a new file and write the content. Human name is used for errors.
def new_file(human_name, filename, content)
  @required_folder = File.dirname(filename)
  FileUtils.mkdir_p @required_folder
  fatal("Unable to create folder for file #{filename}") unless Dir.exist?(@required_folder)
  File.open(filename, "w") do |s|
    s.puts content
  end
  fatal("Failed to create #{human_name} #{filename}") unless File.exist?(filename)
end

# Aborts if the file is not found. Human name is used for errors.
def file_must_exist(filename, human_name)
  fatal("Cannot find #{human_name} #{filename}") unless File.exist?(filename)
end

# Aborts if the ini file is missing this section/key.
def key_must_exist(ini, section, key)
  fatal("Missing ini value #{section}, #{key}") unless ini[section][key]
end

# Load in the given file as an array of strings for yaml metadata and content.
def get_metadata_and_content(filename)
  metadata = Hash.new
  content = ""
  in_meta = false
  lc = 0
  f = File.open(filename, "r")
  f.each_line do |line|
    lc += 1
    if lc == 1 && line.start_with?("---")
      in_meta = true
    elsif lc > 1 && in_meta && line.start_with?("---")
      in_meta = false
    else
      if in_meta
        bits = line.rstrip.split(": ")  # extra space means trim each bit
        fatal("Expected key=value, got #{line}") unless bits.length == 2
        fatal("Key is empty in #{line}") unless bits[0].length > 0
        fatal("Value is empty in #{line}") unless bits[1].length > 0
        metadata[bits[0]] = bits[1]
      else
        content += (line.rstrip + "\n")
      end
    end
  end
  { metadata: metadata, content: content }
end

# Create a new site if requested.
new_site = (ARGV[0] && (ARGV[0] == "new"))
if new_site
  puts "-------------------------------------------"
  puts "Creating new site and content folders"
  fatal("Site folder already exists") if Dir.exist?(@site_folder)
  FileUtils.mkdir_p @content_folder
  fatal("Unable to create folders") unless Dir.exist?(@content_folder)
  new_file("ruthless.ini", @ini_file, "[SITE]
title  = Sample Ruthless Site
blurb  = Welcome to my Ruthless-generated site
footer = Created by <a href='https://github.com/kcartlidge/ruthless' target='_blank'>Ruthless.io</a> and <a href='https://www.ruby-lang.org' target='_blank'>Ruby</a>.
keywords = ruthless,static,site,generator

[OPTIONS]
extentions = false

[SETTINGS]
google-analytics = # AB-123456789-0
disqus-comments  = # account-name

[MENU]
Home = /
Latest News = /news
About = /about")
  new_file("home page", File.join(@content_folder, "index.md"), "---\ntitle: Welcome to Ruthless\n---\n\nFor more information, see [the GitHub repository](https://github.com/kcartlidge/ruthless).\n\n* [Latest News](/news)\n* [About Ruthless](/about)")
  new_file("about page", File.join(@content_folder, "about.md"), "---\ntitle: About Ruthless\n---\n\nLorem ipsum dolor sit amet adipiscing.")
  new_file("sample news page", File.join(@sample_news_folder, "index.md"), "---\ntitle: Latest News\n---\n\nLorem ipsum dolor sit amet adipiscing.\n\n* [Sample News Item 1](sample-news-item-1)\n* [Sample News Item 2](sample-news-item-2)")
  new_file("sample news item 1 page", File.join(@sample_news_folder, "sample-news-item-1.md"), "---\ntitle: Sample News Item #1\ndated: August 27, 2018\nauthor: Ruthless.io\nkeywords: news\n---\n\nLorem ipsum dolor sit amet adipiscing.\n\n* [Back to the Latest News](/news)")
  new_file("sample news item 2 page", File.join(@sample_news_folder, "sample-news-item-2.md"), "---\ntitle: Sample News Item #2\ndated: January 23, 2019\nauthor: Ruthless.io\nkeywords: news\n---\n\nLorem ipsum dolor sit amet adipiscing.\n\n* [Back to the Latest News](/news)")
  new_file("template", @layout_file, "<!DOCTYPE html>
<html lang='en'>
  <head>
    <meta charset='utf-8'>
    <meta http-equiv='X-UA-Compatible' content='IE=edge'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <meta name=generator content='Ruthless (Ruby)'>
    <meta name='keywords' content='{{ sitekeywords }},{{ keywords }}'>
    <meta name='description' content='{{ sitetitle }}'>
    <meta name='robots' content='follow,index,noarchive,noodp'>
    <meta name='google' content='nositelinkssearchbox'>
    <meta name='author' content='{{ author }}'>
    <link href='/theme.css' rel='stylesheet' type='text/css' />
    <title>{{ title}} -- {{ sitetitle }}</title>
  </head>
  <body>
    <header>
      <h1>{{ sitetitle }}</h1>
      <aside>{{ siteblurb }}</aside>
      <nav>
        {% for option in sitemenu %}{{ option }}{% endfor %}
      </nav>
    </header>
    <section>
      <h1>{{ title}}</h1>
      <article>
        {% include 'page' %}
        {% if settings.disqus-comments %}
        <div id='disqus_thread'></div>
        {% endif %}
      </article>
    </section>
    <footer>
      {{ sitefooter }}
    </footer>

    <script>
      var ls = document.links;
      for (var i = 0, ln = ls.length; i < ln; i++) if (ls[i].hostname != window.location.hostname) ls[i].target = '_blank';
    </script>

    {% if settings.google-analytics %}
    <!-- Global Site Tag (gtag.js) - Google Analytics -->
    <script async src='https://www.googletagmanager.com/gtag/js?id={{ settings.google-analytics }}'></script>
    <script>
        window.dataLayer = window.dataLayer || [];

        function gtag() {
            dataLayer.push(arguments)
        };
        gtag('js', new Date());
        gtag('config', '{{ settings.google-analytics }}');
    </script>
    {% endif %}

    {% if settings.disqus-comments %}
    <script>
      var disqus_config = function () {
        this.page.url = ' ';
        this.page.identifier = '{{ title }}';
      };

      (function () {
          var d = document, s = d.createElement('script');

          s.src = '//{{ settings.disqus-comments }}.disqus.com/embed.js';

          s.setAttribute('data-timestamp', +new Date());
          (d.head || d.body).appendChild(s);
      })();
    </script>
    {% endif %}
  </body>
</html>")
  new_file("child template", File.join(@includes_folder, "_dated.liquid"), "<div class='dated'>{{ dated }}</div>")
  new_file("page template", File.join(@includes_folder, "_page.liquid"), "{% if dated %}{% include 'dated' %}{% endif %}\n{{ content }}")
  new_file("theme", @theme_file, "body { font-family: 'Noto Sans', Verdana, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: 13pt; background: #f8f8f8; color: #444; margin: 0; padding: 0.5rem 2rem; }
a { color: #06d; text-decoration: none; border-bottom: solid 1px #8af; }
a:hover { color: #359fe0; }
header, section, footer { max-width: 50rem; margin: 0 auto; }
header { margin-bottom: 4rem; }
section { line-height: 140%; }
footer { margin-top: 5rem; font-size: 0.9rem; }
header nav { margin-top: 0.75rem; }
header nav a { margin-right: 1rem; white-space: nowrap; }
section img { max-width: 10rem; max-height: 10rem; float: right; margin: 1rem 0 1rem 2rem; background: #fff; padding: 0.4rem; box-shadow: 0 0 8px #00000033; }
header h1 { font-size: 1.2rem; margin: 0.25rem 0; }
header aside { color: #666; }
h1 { font-size: 1.75em; color: #000; }
h1,h2,h3,h4,h5,h6 { line-height: 110%; }
table { margin: 2rem 0; }
th, td { padding: 0.1rem 1rem 0.1rem 0; border-bottom: solid 1px #ccc; }
li { margin: 0.25em 0; }
pre { background: #fff; overflow: scroll; border: solid 1px #999; }
code { background: #ddd; }
pre, code { color: #222; padding: 0.2rem 0.3rem; }
pre code { background: #fff; border: 0; padding: 0; }
.dated { font-size: 0.8rem; margin-top: -1.25rem; color: #666; text-transform: uppercase; }")
  done("New site created")
end

# Build the site if requested.
build_site = (ARGV[0] && (ARGV[0] == "build" or ARGV[0] == "serve"))
if build_site
  # Show the folder paths.
  puts "-------------------------------------------"
  puts "Reading " + @site_folder
  puts "Creating " + @html_folder

  # Read and show the site options.
  puts "Reading " + @ini_file
  fatal("ruthless.ini file not found") unless File.exist?(@ini_file)
  ini = IniFile.load(@ini_file)
  key_must_exist(ini, "SITE", "title")
  key_must_exist(ini, "SITE", "blurb")
  key_must_exist(ini, "SITE", "footer")
  @site_title = ini["SITE"]["title"]
  @site_blurb = ini["SITE"]["blurb"]
  @site_footer = ini["SITE"]["footer"]
  @site_keywords = ini["SITE"]["keywords"]
  @extentions = ini["OPTIONS"]["extentions"]
  @settings = ini["SETTINGS"]
  puts "---------------"
  puts @settings
  puts "---------------"

  # Populate the (optional) menu.
  ini.each_section do |section|
    if section == "MENU"
      ini[section].each do |k, v|
        @menu.push("<a href=\"#{v}\">#{k}</a>")
      end
    end
  end

  # Ensure we have required folders/files.
  fatal("Content folder not found") unless Dir.exist?(@content_folder)
  file_must_exist(@layout_file, "layout template")
  file_must_exist(@theme_file, "theme styles")
  Liquid::Template.error_mode = :strict
  Liquid::Template.file_system = Liquid::LocalFileSystem.new(@includes_folder)
  @layout = Liquid::Template.parse(File.read(@layout_file))

  # Ensure we have a fresh, empty, output folder.
  if Dir.exist?(@html_folder)
    puts "Removing output folder"
    fatal("Unable to remove folder") unless FileUtils.rmtree(@html_folder)
  end
  puts "Creating output folder"
  FileUtils.mkdir @html_folder
  fatal("Unable to create folder") unless Dir.exist?(@html_folder)

  # Render the whole site folder tree.
  puts "Rendering output"
  puts "Using page extentions" if @extentions
  puts "  #{File::SEPARATOR}"
  prefix = "#{@content_folder}#{File::SEPARATOR}"
  prefix_length = prefix.length
  FileUtils.copy(@theme_file, File.join(@html_folder, "theme.css"))
  Find.find(@content_folder) do |path|
    next if File.directory? path
    fatal("Expected filename to start with #{prefix} - #{path}") unless path.start_with?(prefix)

    # Derive a path/filename based on the site vs output folders.
    rel_path = File.dirname(path[prefix_length, path.length])
    abs_path = File.join(@html_folder, rel_path)

    # Create (and display) new subfolders as they are needed.
    unless Dir.exist?(abs_path)
      FileUtils.mkdir_p abs_path
      fatal("Unable to create content subfolder #{abs_path}") unless Dir.exist?(abs_path)
      puts "  #{File::SEPARATOR}#{rel_path}"
    end

    # Derive the output filename.
    filename_no_ext = File.basename(path, ".*")
    ext = File.extname(path)
    use_template = (@templatable.include? ext)
    out_filename = File.join(abs_path, filename_no_ext)

    # Extentions/index page? Override for templates else use original.
    if @extentions || !use_template || (filename_no_ext == "index")
      out_filename += use_template ? ".html" : ext
    else
      # No extentions? Create a folder and add an index file.
      unless Dir.exist?(out_filename)
        FileUtils.mkdir_p out_filename
        fatal("Unable to create page folder #{out_filename}") unless Dir.exist?(out_filename)
        out_filename = File.join(out_filename, "index.html")
      end
    end

    # Write out the new file.
    if use_template
      File.open(out_filename, "w") do |file|
        src = get_metadata_and_content(path)
        content = src[:content]
        if ext == ".md"
          content = Kramdown::Document.new(content).to_html
        elsif ext == ".txt"
          content = "<pre>#{content}</pre>"
        end
        data = src[:metadata]
        data["content"] = content
        data["sitetitle"] = @site_title
        data["siteblurb"] = @site_blurb
        data["sitefooter"] = @site_footer
        data["sitekeywords"] = @site_keywords
        data["sitemenu"] = @menu
        data["settings"] = @settings
        content = @layout.render(data).delete("\r")
        file.write content
      end
    else
      FileUtils.copy(path, out_filename)
    end
  end
  puts "-------------------------------------------"
  puts "Generated."
end

# If requested, serve the static site just created.
serve = (ARGV[0] && (ARGV[0] == "serve"))
if serve
  puts "-------------------------------------------"
  puts "Starting static server on http://localhost:1337 ... Ctrl+C stops"
  puts
  root = File.join(File.dirname(__FILE__), "www")
  server = WEBrick::HTTPServer.new Port: 1337, DocumentRoot: root, AccessLog: [], Logger: nil
  trap "INT" do server.shutdown end
  server.start
end

# Done.
puts
puts "Finis."
