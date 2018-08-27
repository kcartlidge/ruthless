#!/usr/bin/ruby

require 'fileutils'
require 'find'
require 'kramdown'
require 'ruby-handlebars'

# Define some of the folder/file options.
@site_folder = File.join(File.dirname(__FILE__),'site')
@content_folder = File.join(File.dirname(__FILE__),'site','content')
@layout_file = File.join(File.dirname(__FILE__),'site','layout.hbs')
@theme_file = File.join(File.dirname(__FILE__),'site','theme.css')
@html_folder = File.join(File.dirname(__FILE__),'www')
@hbs = Handlebars::Handlebars.new

# Helper functions.
def fatal(message)
  puts '---------------------------------------'
  puts 'ERROR: ' + message
  abort
end

def done(message)
  puts message
  exit
end

def new_file(human_name, filename, content)
  File.open(filename,'w') do |s|
    s.puts content
  end
  if not File.exist?(filename)
    fatal("Failed to create #{human_name} " + filename)
  end
end

def must_exist(filename, human_name)
  if not File.exist?(filename)
    fatal("Cannot find #{human_name} " + filename)
  end
end

# Show the intro.
puts
puts 'RUTHLESS  https://ruthless.io'
puts 'Ruthlessly simple static site generator'
puts
puts ' --site    Create a new site'
puts

# Create a new site if requested.
new_site = ARGV[0] and ARGV[0] == '--site'
if new_site
  puts '---------------------------------------'
  puts 'Creating new site and content folders'
  if Dir.exist?(@site_folder)
    fatal('Site folder already exists')
  end
    FileUtils.mkdir_p @content_folder
  if not Dir.exist?(@content_folder)
    fatal('Unable to create folders')
  end
  new_file('home page', File.join(@content_folder,'index.md'),"# Edit 'site/content/index.md'")
  new_file('template',@layout_file,"<html>
  <head><link href='theme.css' rel='stylesheet' type='text/css' /><meta charset='utf-8' /></head>
  <body>
    <div id='site-title'>{{ sitetitle }}</div>
    <div id='site-blurb'>{{ siteblurb }}</div>
    <div id='main'>
{{ content }}
    </div>
  </body>
</html>")
  new_file('theme',@theme_file,'body { font-family: sans-serif; font-size: 13pt; }')
  done('New site created')
end

# Show the options.
puts '---------------------------------------'
puts 'Reading  ' + @site_folder
puts 'Creating ' + @html_folder

# Ensure we have required folders/files.
if not Dir.exist?(@content_folder)
  fatal('Content folder not found')
end
must_exist(@layout_file, 'layout template')
must_exist(@theme_file, 'theme styles')
@layout = @hbs.compile(File.read @layout_file)

# Ensure we have a fresh, empty, output folder.
if Dir.exist?(@html_folder)
  puts 'Removing output folder'
  if not FileUtils.rmtree(@html_folder)
    fatal('Unable to remove folder')
  end
end
puts 'Creating output folder'
FileUtils.mkdir @html_folder
if not Dir.exist?(@html_folder)
  fatal('Unable to create folder')
end

# Render the whole site folder tree.
puts 'Rendering output'
prefix = @content_folder + '/'
prefix_length = prefix.length
FileUtils.copy(@theme_file,File.join(@html_folder,'theme.css'))
Find.find(@content_folder) do |path|

  # Only handling Markdown files initially.
  if File.extname(path) == '.md'
    if not path.start_with?(prefix)
      fatal('Expected filename to start with ' + prefix)
    end

    # Derive a path/filename based on the site vs output folders.
    rel_path = File.dirname(path[prefix_length, path.length])
    abs_path = File.join(@html_folder, rel_path)

    # Create (and display) new subfolders as they are needed.
    if not Dir.exist?(abs_path)
      FileUtils.mkdir_p abs_path
      if not Dir.exist?(abs_path)
        fatal('Unable to create content subfolder ' + abs_path)
      end
      puts '  /' + rel_path
    end

    # Write out the new file.
    basename = File.basename(path, '.md')
    abs_html = File.join(abs_path, basename + '.html')
    File.open(abs_html, 'w') do |file|
      opts = {auto_ids:false,syntax_highlighter:'rouge',default_lang:'text'}
      kdoc = Kramdown::Document.new(File.read(path),opts)
      html = kdoc.to_html
      html = @layout.call({
        content:html,
        sitetitle:'ruthless.io',
        siteblurb:'Ruthlessly simple static site generator, written in Ruby.'
      })
      file.write html
    end
  end

end

# Done.
puts '---------------------------------------'
