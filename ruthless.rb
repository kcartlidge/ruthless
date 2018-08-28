#!/usr/bin/ruby

require 'fileutils'
require 'find'
require 'redcarpet'
require 'liquid'

# Define some of the folder/file options.
@site_folder = File.join(File.dirname(__FILE__), 'site')
@content_folder = File.join(File.dirname(__FILE__), 'site', 'content')
@layout_file = File.join(File.dirname(__FILE__), 'site', 'layout.liquid')
@theme_file = File.join(File.dirname(__FILE__), 'site', 'theme.css')
@html_folder = File.join(File.dirname(__FILE__), 'www')

# Set up markdown rendering defaults.
md_opts = {
  tables: true,
  no_intra_emphasis: true,
  highlight: true,
  fenced_code_blocks: true,
  autolink: true,
  strikethrough: true,
  space_after_headers: true
}
@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, md_opts)

# Display the error message then abort.
def fatal(message)
  puts '---------------------------------------'
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
  File.open(filename, 'w') do |s|
    s.puts content
  end
  fatal("Failed to create #{human_name} #{filename}") unless File.exist?(filename)
end

# Aborts if the file is not found. Human name is used for errors.
def must_exist(filename, human_name)
  fatal("Cannot find #{human_name} #{filename}") unless File.exist?(filename)
end

# Show the intro.
puts
puts 'RUTHLESS  https://ruthless.io'
puts 'Ruthlessly simple static site generator'
puts
puts ' --site    Create a new site'
puts

# Create a new site if requested.
new_site = (ARGV[0] && (ARGV[0] == '--site'))
if new_site
  puts '---------------------------------------'
  puts 'Creating new site and content folders'
  fatal('Site folder already exists') if Dir.exist?(@site_folder)
  FileUtils.mkdir_p @content_folder
  fatal('Unable to create folders') unless Dir.exist?(@content_folder)
  new_file('home page', File.join(@content_folder, 'index.md'), "# Welcome to Ruthless

To change what appears here ...

* edit 'site/content/index.md' to provide your own content
* run ```ruby ruthless.rb``` to regenerate the static version
* reload this page to see your changes
* add more content pages, including subfolders
* update ```layout.liquid``` and ```theme.css``` to set your look and feel

[How to do Links](how-to-do-links.html)
[Change the Look and Feel](look-and-feel.html)")
  new_file('link example', File.join(@content_folder, 'how-to-do-links.md'), "# How to do Links

Links are done in the normal Markdown way:

```` markdown
[Back to the home page](index.html)
````

To target your own pages note that only extentions (not file names) are changed when creating the static site.
This means you target the *existing* folder/file names as per the original folder/file structure in ```content```.
Therefore it is suggested your content filenames are *slugs* (e.g. ```this-page``` not ```This Page```).
Whether you need ```.html``` depends upon whether you activate simple URLs.

The default template will automatically (via JavaScript) add a ```target``` attribute to any links that have a protocol.
For example ```[Liquid](https://shopify.github.io/liquid/)``` looks like: [Liquid](https://shopify.github.io/liquid/)

[Back to the home page](index.html)")
  new_file('theming', File.join(@content_folder, 'look-and-feel.md'), "# Change the Look and Feel

To set the look and feel ...

* your layout is a [Liquid](https://shopify.github.io/liquid/) template in your ```content``` folder named ```layout.liquid```
* the style sheet is standard CSS in your ```content``` folder named ```theme.css```

[Back to the home page](index.html)")
  new_file('template', @layout_file, "<html>
  <head><link href='theme.css' rel='stylesheet' type='text/css' /><meta charset='utf-8' /></head>
  <body>
    <div id='header'>
      <div id='site-title'>{{ sitetitle }}</div>
      <div id='site-blurb'>{{ siteblurb }}</div>
    </div>
    <div id='main'>
      {{ content }}
    </div>
    <script>
      var ls = document.links;
      for (var i = 0, ln = ls.length; i < ln; i++) {
        if (ls[i].hostname != window.location.hostname) {
          ls[i].target = '_blank';
          ls[i].title = 'Opens in a new tab/window';
          ls[i].className = (ls[i].className + ' external-link').trim();
        }
      }
    </script>
  </body>
</html>")
  new_file('theme', @theme_file, "@import url('https://fonts.googleapis.com/css?family=Noto+Sans:400,700');
html,body,p,* { line-height: 150%; }
body { font-family: 'Noto Sans', Verdana, 'Helvetica Neue', Helvetica, sans-serif; font-size: 14pt; background: #f8f8f8; color: #444; margin: 0; padding: 0; }
#header, #main { margin: 0; padding: 0.5rem 2rem; }
#site-title { font-size: 1.5rem; text-transform: uppercase; color: #368; }
#site-blurb { font-size: 1.1rem; }
h1,h2,h3,h4,h5,h6 { margin: 0; padding: 1rem 0; line-height: 110%; }
h1 { font-weight: bold; }
pre { background: #fff; padding: 0.5rem; overflow: scroll; }
code { background: #fff; padding: 0.1rem 0.25rem; }
a { line-height: 120%; color: #06d; display: inline-block; padding: 0; margin: 0 0.2rem; text-decoration: none; border-bottom: none; }
a:hover { color: #0073aa; border-bottom: solid 1px #0073aa; }
a.external-link:after { vertical-align: top; font-size: 0.7em; content: ' (ext)' }
@media (min-width: 40rem) {
  #header, #main { width: 50rem; margin: 0 auto; }
}
")
  done('New site created')
end

# Show the options.
puts '---------------------------------------'
puts 'Reading ' + @site_folder
puts 'Creating ' + @html_folder

# Ensure we have required folders/files.
fatal('Content folder not found') unless Dir.exist?(@content_folder)
must_exist(@layout_file, 'layout template')
must_exist(@theme_file, 'theme styles')
Liquid::Template.error_mode = :strict
@layout = Liquid::Template.parse(File.read(@layout_file))

# Ensure we have a fresh, empty, output folder.
if Dir.exist?(@html_folder)
  puts 'Removing output folder'
  fatal('Unable to remove folder') unless FileUtils.rmtree(@html_folder)
end
puts 'Creating output folder'
FileUtils.mkdir @html_folder
fatal('Unable to create folder') unless Dir.exist?(@html_folder)

# Render the whole site folder tree.
puts 'Rendering output'
puts '  /'
prefix = @content_folder + '/'
prefix_length = prefix.length
FileUtils.copy(@theme_file, File.join(@html_folder, 'theme.css'))
Find.find(@content_folder) do |path|
  # Only handling Markdown files initially.
  next unless File.extname(path) == '.md'
  fatal("Expected filename to start with #{prefix}") unless path.start_with?(prefix)

  # Derive a path/filename based on the site vs output folders.
  rel_path = File.dirname(path[prefix_length, path.length])
  abs_path = File.join(@html_folder, rel_path)

  # Create (and display) new subfolders as they are needed.
  unless Dir.exist?(abs_path)
    FileUtils.mkdir_p abs_path
    fatal("Unable to create content subfolder #{abs_path}") unless Dir.exist?(abs_path)
    puts '  /' + rel_path
  end

  # Write out the new file.
  basename = File.basename(path, '.md')
  abs_html = File.join(abs_path, "#{basename}.html")
  File.open(abs_html, 'w') do |file|
    html = @markdown.render(File.read(path))
    html = @layout.render(
      'content' => html,
      'sitetitle' => 'ruthless.io',
      'siteblurb' => 'Ruthlessly simple static site generator, written in Ruby.'
    )
    file.write html
  end
end

# Done.
puts '---------------------------------------'
puts 'finis.'
