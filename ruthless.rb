#!/usr/bin/ruby

require 'fileutils'

# Define some of the folder/file options.
@site_folder = File.join(File.dirname(__FILE__),'site')
@content_folder = File.join(File.dirname(__FILE__),'site','content')
@layout_file = File.join(File.dirname(__FILE__),'site','layout.html')
@theme_file = File.join(File.dirname(__FILE__),'site','theme.css')
@html_folder = File.join(File.dirname(__FILE__),'www')

# Show the intro.
puts
puts 'RUTHLESS  https://ruthless.io'
puts 'Ruthlessly simple static site generator'
puts

# Show the options.
puts '---------------------------------------'
puts 'Reading  ' + @site_folder
puts 'Creating ' + @html_folder

# Done.
puts '---------------------------------------'
