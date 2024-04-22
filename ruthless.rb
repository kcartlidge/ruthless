#!/usr/bin/ruby

@version = '3.0.2'

puts 'Ensuring dependencies (slower first time).'
require 'fileutils'
require 'find'
require 'set'
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'inifile'
  gem 'kramdown'
  gem 'liquid'
  gem 'webrick'
  gem 'htmlbeautifier'
end

# Get the command arguments.
@new_site = (ARGV[0] && (ARGV[0] == 'new'))
@build_site = (ARGV[0] && (ARGV[0] == 'build'))
@serve_site = (ARGV[0] && (ARGV[0] == 'serve'))
@folder = ARGV[1] unless ARGV.length < 2

# Define some vars.
@templatable = %w[.md .txt].to_set
@menu = []

# -------------------------------------------------------------
# Define functions - code is below
# -------------------------------------------------------------

# Display the error message then abort.
def fatal(message)
  puts '-------------------------------------------'
  puts "ERROR: #{message}"
  abort
end

# Display the message then exit.
def done(message)
  puts
  puts message
  puts
  exit
end

# Show some introductory/explanatory text.
def show_intro
  puts
  puts "RUTHLESS #{@version}"
  puts 'Ruthlessly simple static site generator'
  puts "https://github.com/kcartlidge/ruthless"
  puts
  puts 'ruby ruthless.rb <command>'
  puts '  new <folder>    Create a new site'
  puts '  build <folder>  Generate site output'
  puts '  serve <folder>  Build and serve a site'
  puts
  puts 'The <folder> should have a "site" subfolder.'
  puts 'Builds are written to a sibling "www" folder.'
  puts 'If in doubt, run with "new" to see an example.'
  puts
end

# Create a new file and write the content. Human name is used for errors.
def new_file(human_name, filename, content)
  @required_folder = File.dirname(filename)
  FileUtils.mkdir_p @required_folder
  fatal("Unable to create folder for file #{filename}") unless Dir.exist?(@required_folder)
  File.open(filename, 'w') do |s|
    s.puts content
  end
  fatal("Failed to create #{human_name} #{filename}") unless File.exist?(filename)
end

# Aborts if the file is not found. Human name is used for errors.
def file_must_exist(filename, human_name)
  fatal("Cannot find #{human_name} #{filename}") unless File.exist?(filename)
end

# Aborts if a given ini file is missing a section/key.
def key_must_exist(ini, section, key)
  fatal("Missing ini value #{section}, #{key}") unless ini[section][key]
end

# Load in the given file as an array of strings for yaml metadata and content.
# Optionally content can be skipped and it will be empty on return.
def get_metadata_and_content(filename, skip_content = false)
  metadata = Hash.new
  content = ''
  in_meta = false
  lc = 0
  f = File.open(filename, 'r')
  f.each_line do |line|
    lc += 1
    if lc == 1 && line.start_with?('---')
      in_meta = true
    elsif lc > 1 && in_meta && line.start_with?('---')
      in_meta = false
      if skip_content
        break
      end
    else
      if in_meta
        bits = line.rstrip.split(': ')  # extra space means trim each bit
        fatal("Expected key=value, got #{line}") unless bits.length == 2
        fatal("Key is empty in #{line}") unless bits[0].length > 0
        fatal("Value is empty in #{line}") unless bits[1].length > 0
        metadata[bits[0]] = bits[1]
      else
        content += (line.rstrip + "\n")
      end
    end
  end

  # Generate a fixed-width key for sorting items.
  # This is the 'sequence|datetime|title', with defaults if not provided.
  # We reverse the sequence because the link generation does a reverse
  # itself to apply date-descending, which means the sequence portion of
  # the key will also be reversed and so we correct for it in advance.
  seq = '00000'
  dtm = ttl = '197001010000'
  begin
    if metadata['sequence'] != nil
      seq = 99999 -metadata['sequence'].to_i
      seq = sprintf("%05d", seq)
    end
    dtm = Date.parse(metadata['dated']).strftime('%Y%m%d%H%M') unless metadata['dated'] == nil
    metadata['dated'] = Date.parse(metadata['dated']).strftime('%d %B, %Y') unless metadata['dated'] == nil
  rescue
    # no action needed.
  end
  ttl = metadata['title'] unless metadata['title'] == nil
  metadata['sortkey'] = "#{seq}|#{dtm}|#{ttl}"
  { metadata: metadata, content: content }
end

def define_folders
  # Define folder/file locations.
  if @folder
    @content_folder = File.join(@site_folder, 'content')
    @layouts_folder = File.join(@site_folder, 'themes', 'default')
    if @custom_theme
      @layouts_folder = File.join(@site_folder, @custom_theme)
      puts 'Setting theme to ' + @layouts_folder
    end
    @includes_folder = File.join(@layouts_folder, 'includes')
    @sample_news_folder = File.join(@content_folder, 'news')
    @sample_article_folder = File.join(@content_folder, 'articles')
    @layout_file = File.join(@layouts_folder, 'layout.liquid')
    @theme_file = File.join(@layouts_folder, 'theme.css')
  end
end

def do_create
  define_folders

  puts '-------------------------------------------'
  puts 'Creating new site and content folders'
  fatal('Site folder already exists') if Dir.exist?(@site_folder)
  FileUtils.mkdir_p @content_folder
  fatal('Unable to create folders') unless Dir.exist?(@content_folder)
  new_file('ruthless.ini', @ini_file, "[SITE]
title    = Sample Ruthless Site
blurb    = Welcome to my Ruthless-generated site
footer   = Created by <a href='https://github.com/kcartlidge/ruthless' target='_blank'>Ruthless</a> and <a href='https://www.ruby-lang.org' target='_blank'>Ruby</a>.
keywords = ruthless,static,site,generator
theme    = themes/default

[OPTIONS]
extentions = false

[SETTINGS]
# google-analytics = AB-123456789-0
# disqus-comments  = account-name

[MENU]
Home = /
Latest News = /news
Articles = /articles
About = /about")
  lipsum = "\n\nSed lobortis ut sem a dapibus. Pellentesque condimentum id tellus et pellentesque. Cras ullamcorper fermentum pharetra. Cras ac justo tellus. Duis non convallis massa. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; *Ut ac magna a lacus* lobortis faucibus quis id ligula."
  lipsum += lipsum
  new_file('home page', File.join(@content_folder, 'index.md'), "---\ntitle: Welcome to Ruthless\n---\n\n**For more information**, see [the GitHub repository](https://github.com/kcartlidge/ruthless).\n\n* [Latest News](/news)\n* [About Ruthless](/about)" + lipsum)
  new_file('about page', File.join(@content_folder, 'about.md'), "---\ntitle: About Ruthless\n---\n\n**Lorem ipsum** dolor sit amet adipiscing." + lipsum)
  new_file('sample news page', File.join(@sample_news_folder, 'index.md'), "---\ntitle: Latest News\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n[[INDEX]]\n\n---\n\n" + lipsum)
  new_file('sample news item 1 page', File.join(@sample_news_folder, 'sample-news-item-1.md'), "---\ntitle: Sample News Item #1\ndated: August 27, 2023\nauthor: Ruthless\nkeywords: news\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n* [Back to the Latest News](/news)" + lipsum)
  new_file('sample news item 2 page', File.join(@sample_news_folder, 'sample-news-item-2.md'), "---\ntitle: Sample News Item #2\ndated: January 23, 2024\nauthor: Ruthless\nkeywords: news\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n* [Back to the Latest News](/news)" + lipsum)
  new_file('sample undated news item', File.join(@sample_news_folder, 'sample-undated-news-item.md'), "---\ntitle: Sample Undated News Item\nauthor: Ruthless\nkeywords: news\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n* [Back to the Latest News](/news)" + lipsum)
  new_file('sample articles', File.join(@sample_article_folder, 'index.md'), "---\ntitle: Sample Articles\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n[[INDEX]]\n\n---\n\n" + lipsum)
  new_file('sample article 1', File.join(@sample_article_folder, 'sample-article-1.md'), "---\ntitle: Sample Article #1\nsequence: 1\nauthor: Ruthless\nkeywords: article\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n* [Back to the Articles](/articles)" + lipsum)
  new_file('sample article 2', File.join(@sample_article_folder, 'sample-article-2.md'), "---\ntitle: Sample Article #2\nsequence: 2\nauthor: Ruthless\nkeywords: article\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n* [Back to the Articles](/articles)" + lipsum)
  new_file('sample unsequenced article', File.join(@sample_article_folder, 'sample-unsequenced-article.md'), "---\ntitle: Sample Unsequenced Article\nauthor: Ruthless\nkeywords: article\n---\n\n**Lorem ipsum** dolor sit amet adipiscing.\n\n* [Back to the Articles](/articles)" + lipsum)
  new_file('template', @layout_file, "<!DOCTYPE html>
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
  <link rel='icon' type='image/png' sizes='32x32' href='/favicon-32x32.png?v={{ randomver }}'>
  <link rel='icon' type='image/png' sizes='16x16' href='/favicon-16x16.png?v={{ randomver }}'>
  <link rel='shortcut icon' href='/favicon.ico?v={{ randomver }}'>
  <link rel='apple-touch-icon' sizes='180x180' href='/apple-touch-icon.png?v={{ randomver }}'>
  <link rel='manifest' href='/site.webmanifest?v={{ randomver }}'>
  <link href='/theme.css?v={{ randomver }}' rel='stylesheet' type='text/css' />
  <title>{{ title}} -- {{ sitetitle }}</title>
</head>
<body>

  <header>
    <div class='inner'>
      <h1>{{ sitetitle }}</h1>
      <aside>{{ siteblurb }}</aside>
    </div>
  </header>
  <nav>
    <div class='inner'>
    {% for option in sitemenu %}{{ option }}{% endfor %}
    </div>
  </nav>

  <main>
    <div class='inner'>
      <h1>{{ title}}</h1>
      <article>
        {% include 'page' %}
        {% if settings.disqus-comments %}
        <div id='disqus_thread'></div>
        {% endif %}
      </article>
    </div>
  </main>

  <footer>
    <div class='inner'>
      {{ sitefooter }}
    </div>
  </footer>

  <script>
    // Make all external links open in a new tab/window.
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
      // this.page.url = ' ';
      this.page.identifier = '{{ title }}';
    };
    (function () {
      var d = document, s = d.createElement('script');
      s.src = 'https://{{ settings.disqus-comments }}.disqus.com/embed.js';
      s.setAttribute('data-timestamp', +new Date());
      (d.head || d.body).appendChild(s);
    })();
  </script>
  {% endif %}

</body>
</html>")
  new_file('child template', File.join(@includes_folder, '_dated.liquid'), "<div class='dated'>{{ dated }}</div>")
  new_file('page template', File.join(@includes_folder, '_page.liquid'), "{% if dated %}{% include 'dated' %}{% endif %}\n{{ content }}")
  new_file('default theme', @theme_file, "html { box-sizing: border-box; overflow-y: scroll; }
body { background: #f8f8f8; color: #111; margin: 0; padding: 0; }
html, body { font-family: 'Noto Sans', Verdana, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; font-size: 14px; }
html, body, * { cursor: default; line-height: 145%; }
a { cursor: pointer; color: #1e6dac; text-decoration: none; border-bottom: solid 1px #8af; }
a:hover { color: #085a6e; border-bottom: 2px solid #468c9e; }
header, nav, main, footer { }
header { background: #1b4b81; background: repeating-linear-gradient(135deg,#1b4b81,#1b4b81 200px,#205086 200px,#205086 400px); padding-top: 0.4rem; padding-bottom: 0.6rem; }
nav { background: #ddd; }
nav .inner { padding-top: 0.4rem; padding-bottom: 0.3rem; }
nav a { border: none; padding: 0.3rem 0.75rem 0.4rem 0.75rem; display: inline-block; background: #456a93; color: #fff; margin: 0 0.2rem 0.2rem 0; font-size: 1rem; white-space: nowrap; }
nav a:hover { border: none; background: #1e5085; color: #fff; }
main { line-height: 140%; }
main img { max-width: 14rem; float: right; margin: 1rem 0 1rem 2rem; background: #fff; padding: 0.4rem; box-shadow: 0 0 8px #00000033; transform: rotate(3deg); }
header h1 { font-size: 1.6rem; margin: 0.25rem 0; color: #fff; }
header aside { color: #ccc; }
footer { font-size: 0.8rem; padding: 3rem 0 1rem 0; }
.inner { margin: 0 auto; min-width: 20rem; max-width: 70rem; padding: 0.5rem 4rem; }
h1 { font-size: 2em; color: #000; letter-spacing: -1px; color: #114770; }
h1,h2,h3,h4,h5,h6 { line-height: 110%; }
table { margin: 2rem 0; background: #fff; border: solid 2px #ccc; }
th, td { padding: 0.1rem 0.5rem; border-bottom: solid 1px #ccc; }
ul, ol { padding-left: 2rem; }
li { margin: 0.4em 0; }
blockquote { background: #e5e5e5; margin: 1.5rem 2rem 1.5rem 3rem; padding: 0.4rem 1.5rem; }
pre { font-family: 'PT Mono', Cousine, 'Roboto Mono', Monaco, 'Courier New', Courier, monospace; font-size: 90%; box-shadow: 0 0 4px rgba(0, 0, 0, 0.2); background: #fff; border: solid 2px #777; margin: 2rem 0; padding: 0.75rem 1rem; overflow-x: auto; }
code { display: inline; background: #fff; box-shadow: 0 0 4px rgba(0, 0, 0, 0.2); font-size: 1.1em; text-indent: 0; margin: 0 0.2em; padding: 0.1rem 0.3rem; border: solid 1px #777; }
pre, code { color: #222; }
pre code { display: block; box-shadow: none; background: #fff; padding: 0; border: 0; }
div.dated { display: inline-block; padding: 0.2rem 0.6rem; text-transform: uppercase; background: #d5d5d5; }
li .dated { display: inline-block; vertical-align: middle; margin: 0; padding-left: 0.5rem; font-size: 0.9rem; color: #888; }
@media only screen and (max-width: 45rem) { article img { max-width: 9rem; } }
")
  done('New site created - favicons are needed (eg https://favicon.io)')
end

def do_build
  # Show the folder paths.
  start = Time.now
  puts '-------------------------------------------'
  puts 'Reading ' + @site_folder
  puts 'Creating ' + @html_folder

  # Read and show the site options.
  puts 'Reading ' + @ini_file
  fatal('ruthless.ini file not found') unless File.exist?(@ini_file)
  ini = IniFile.load(@ini_file)
  key_must_exist(ini, 'SITE', 'title')
  key_must_exist(ini, 'SITE', 'blurb')
  key_must_exist(ini, 'SITE', 'footer')
  @site_title = ini['SITE']['title']
  @site_blurb = ini['SITE']['blurb']
  @site_footer = ini['SITE']['footer']
  @custom_theme = ini['SITE']['theme']
  @site_keywords = ini['SITE']['keywords']
  @extentions = ini['OPTIONS']['extentions']
  @settings = ini['SETTINGS']

  # Populate the (optional) menu.
  @menu = []
  ini.each_section do |section|
    if section == 'MENU'
      ini[section].each do |k, v|
        @menu.push("<a href=\"#{v}\">#{k}</a>")
      end
    end
  end

  define_folders

  # Ensure we have required folders/files.
  fatal('Content folder not found') unless Dir.exist?(@content_folder)
  file_must_exist(@layout_file, 'layout template')
  file_must_exist(@theme_file, 'theme styles')
  Liquid::Template.error_mode = :strict
  Liquid::Template.file_system = Liquid::LocalFileSystem.new(@includes_folder)
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
  puts 'Using page extentions' if @extentions
  puts "  #{File::SEPARATOR}"
  prefix = "#{@content_folder}#{File::SEPARATOR}"
  prefix_length = prefix.length
  index_cache = Hash.new()
  FileUtils.copy(@theme_file, File.join(@html_folder, 'theme.css'))
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
    filename_no_ext = File.basename(path, '.*')
    ext = File.extname(path)
    use_template = (@templatable.include? ext)
    out_filename = File.join(abs_path, filename_no_ext)

    # Extentions/index page? Override for templates else use original.
    if @extentions || !use_template || (filename_no_ext == 'index')
      out_filename += use_template ? '.html' : ext
    else
      # No extentions? Create a folder and add an index file.
      unless Dir.exist?(out_filename)
        FileUtils.mkdir_p out_filename
        fatal("Unable to create page folder #{out_filename}") unless Dir.exist?(out_filename)
        out_filename = File.join(out_filename, 'index.html')
      end
    end

    # Write out the new file.
    if use_template
      File.open(out_filename, 'w') do |file|
        src = get_metadata_and_content(path)
        content = src[:content]

        # Embed any index lists.
        # Use a cache in case multiple pages want the same index.
        if content.include?('[[INDEX]]')
          folder = File.dirname(path)
          md_list = ''
          if index_cache[folder] != nil
            # Use a cached version.
            md_list = index_cache[folder]
          else
            # Scan all items at this level (only).
            links = Hash.new()
            Dir.each_child(folder) do |item_file|
              # Skip folders.
              item_path = File.join(folder, item_file)
              next if File.directory? item_path

              # Skip the index file itself.
              lnk_filename = File.basename(item_file, '.*')
              next if lnk_filename == 'index'

              # Derive the basics, including path-aware links.
              lnk_meta = get_metadata_and_content(item_path, true)[:metadata]
              lnk_rel = item_path[prefix_length, item_path.length]
              lnk_ext = File.extname(lnk_rel)
              if lnk_ext != nil
                lnk_rel = lnk_rel[0..(lnk_rel.length - lnk_ext.length - 1)]
              end
              lnk_title = lnk_rel
              lnk_title = lnk_meta['title'] if lnk_meta['title'] != nil
              lnk_suffix = ''
              lnk_suffix =  "<span class='dated'>#{lnk_meta['dated']}</span>" if lnk_meta['dated'] != nil

              # Store in a hash keyed by the sortkey.
              links[lnk_meta['sortkey']] = "- [#{lnk_title}](/#{lnk_rel})#{lnk_suffix}\n"
            end

            # Reverse the sort key to generate links from the hash.
            # See get_metadata_and_content for an explanation of why
            # this does dates descending but sequences ascending.
            links = links.sort_by { |k,v| k }
            links.reverse.each do |link|
              md_list += link[1]
            end

            # Add to the cache in case it's requested by a sibling.
            index_cache[folder] = md_list
          end
          content.sub!("[[INDEX]]", md_list)
        end

        # Render.
        if ext == '.md'
          opts = { parse_block_html: true }
          content = Kramdown::Document.new(content, opts).to_html
        elsif ext == '.txt'
          content = "<pre>#{content}</pre>"
        end

        data = src[:metadata]
        data['content'] = content
        data['sitetitle'] = @site_title
        data['siteblurb'] = @site_blurb
        data['sitefooter'] = @site_footer
        data['sitekeywords'] = @site_keywords
        data['randomver'] = ('a'..'z').to_a.shuffle[0,12].join
        data['sitemenu'] = @menu
        data['settings'] = @settings
        content = @layout.render(data).delete("\r")

        content = HtmlBeautifier.beautify(content)

        file.write content
      end
    else
      FileUtils.copy(path, out_filename)
    end
  end
  puts '-------------------------------------------'
  elapsed = (Time.now - start).round(2)
  puts("Generated in #{elapsed} second(s)")
end

def do_serve
  puts '-------------------------------------------'
  puts 'Starting static server on http://localhost:1337 ... Ctrl+C stops'
  puts
  root = @html_folder
  server = WEBrick::HTTPServer.new Port: 1337, DocumentRoot: root, AccessLog: [], Logger: nil
  trap 'INT' do server.shutdown end
  server.start
end

# Return true/false deending upon user confirmation of quitting
def confirm_quit
  choice = ''
  while choice == ''
    puts("(R)estart or (Q)uit?")
    answer = STDIN.gets.strip.upcase
    if answer == 'R' or answer == 'Q' then return answer == 'Q' end
  end
end

# -------------------------------------------------------------
# Do the work
# -------------------------------------------------------------

show_intro
fatal('No folder specified') if ARGV.length < 2

# Headline folders.
@site_folder = File.join(File.dirname(__FILE__), @folder, 'site')
@html_folder = File.join(File.dirname(__FILE__), @folder, 'www')
@ini_file = File.join(@site_folder, 'ruthless.ini')

if @new_site
  # One-off creation.
  puts 'Creating new site skeleton.'
  do_create
elsif @build_site
  # One-off build.
  puts 'Building site.'
  do_build
elsif @serve_site
  # Repeatedly do the work (with Ctrl-C to stop an iteration)
  puts 'Building and serving site.'
  ongoing = true
  while ongoing
    do_build
    do_serve
    puts
    ongoing = !confirm_quit
    puts
  end
end

done('Finis.')
