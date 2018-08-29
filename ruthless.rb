#!/usr/bin/ruby

puts '[ensuring dependencies]'

require 'fileutils'
require 'find'
require 'set'
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'inifile'
  gem 'redcarpet'
  gem 'liquid'
  gem 'webrick'
end

# Define some of the folder/file options.
@site_folder = File.join(File.dirname(__FILE__), 'site')
@content_folder = File.join(File.dirname(__FILE__), 'site', 'content')
@ini_file = File.join(@site_folder, 'ruthless.ini')
@layout_file = File.join(File.dirname(__FILE__), 'site', 'layout.liquid')
@theme_file = File.join(File.dirname(__FILE__), 'site', 'theme.css')
@html_folder = File.join(File.dirname(__FILE__), 'www')
@templatable = ['.md', '.txt'].to_set

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
def file_must_exist(filename, human_name)
  fatal("Cannot find #{human_name} #{filename}") unless File.exist?(filename)
end

# Aborts if the ini file is missing this section/key.
def key_must_exist(ini, section, key)
  fatal("Missing ini value #{section}, #{key}") unless ini[section][key]
end

# Show the intro.
puts
puts 'RUTHLESS 0.6.0  https://ruthless.io'
puts 'Ruthlessly simple static site generator'
puts
puts ' --site    Create a new base site'
puts ' --serve   Create and also serve the site'
puts

# Create a new site if requested.
new_site = (ARGV[0] && (ARGV[0] == '--site'))
if new_site
  puts '---------------------------------------'
  puts 'Creating new site and content folders'
  fatal('Site folder already exists') if Dir.exist?(@site_folder)
  FileUtils.mkdir_p @content_folder
  fatal('Unable to create folders') unless Dir.exist?(@content_folder)
  new_file('ruthless.ini', @ini_file, "[SITE]
title  = Your Site Name
blurb  = Welcome to my ruthless-generated site
footer = Created by <a href='https://ruthless.io' target='_blank'>ruthless.io</a> and <a href='https://www.ruby-lang.org' target='_blank'>Ruby</a>.")
  new_file('home page', File.join(@content_folder, 'index.md'), "# Welcome to Ruthless

For more information, see [the web site](https://ruthless.io).")
  new_file('template', @layout_file, "<html>
  <head>
    <link href='/theme.css' rel='stylesheet' type='text/css' /><meta charset='utf-8' />
    <title>{{ sitetitle }}</title>
  </head>
  <body>
    <div>
      <strong>{{ sitetitle }}</strong><br />
      {{ siteblurb }}
    </div>
    {{ content }}
    <br />
    <p>
      <small>{{ sitefooter }}</small>
    </p>
    <script>
      var ls = document.links;
      for (var i = 0, ln = ls.length; i < ln; i++) if (ls[i].hostname != window.location.hostname) ls[i].target = '_blank';
    </script>
  </body>
</html>")
  new_file('theme', @theme_file, "body { font-family: 'Noto Sans', Verdana, 'Helvetica Neue', Helvetica, sans-serif; font-size: 14pt; background: #f8f8f8; color: #444; margin: 0; padding: 2rem; }")
  done('New site created')
end

# Show the folder paths.
puts '---------------------------------------'
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

# Ensure we have required folders/files.
fatal('Content folder not found') unless Dir.exist?(@content_folder)
file_must_exist(@layout_file, 'layout template')
file_must_exist(@theme_file, 'theme styles')
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
puts "  #{File::SEPARATOR}"
prefix = "#{@content_folder}#{File::SEPARATOR}"
prefix_length = prefix.length
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
  out_filename += use_template ? '.html' : ext

  # Write out the new file.
  # This could handle non-text files more efficiently.
  # Clarity is currently taking precedence (as it works).
  File.open(out_filename, 'w') do |file|
    content = File.read(path)
    if ext == '.md'
      content = @markdown.render(content)
    elsif ext == '.txt'
      content = "<pre>#{content}</pre>"
    end
    if use_template
      content = @layout.render(
        'content' => content,
        'sitetitle' => @site_title,
        'siteblurb' => @site_blurb,
        'sitefooter' => @site_footer
      )
    end
    file.write content
  end
end
puts '---------------------------------------'
puts 'Generated.'

# If requested, serve the static site just created.
serve = (ARGV[0] && (ARGV[0] == '--serve'))
if serve
  puts '---------------------------------------'
  puts 'Creating new site and content folders'
  puts
  puts 'Starting static server on http://localhost:1337 ... Ctrl+C stops'
  puts
  root = File.join(File.dirname(__FILE__), 'www')
  server = WEBrick::HTTPServer.new Port: 1337, DocumentRoot: root, AccessLog: [], Logger: nil
  trap 'INT' do server.shutdown end
  server.start
end

# Done.
puts
puts 'Finis.'
