#!/usr/bin/env ruby

# In help we want to refer to the program as 'm' instead of 'm.rb'
# and in other places we want syntax highlighting.
$PROGRAM_NAME = 'm'

$LOAD_PATH << File.join(__dir__, 'lib')

require 'thor'       # the main CLI framework
require 'all'        # include all the local things

class App < Thor
  include Thor::Actions

  class_option :verbose, type: :boolean

  def self.exit_on_failure?
    true
  end

  desc 'howdy', 'Say howdy'
  subcommand 'howdy', Howdy

  desc 'templates', 'List top all templates'
  subcommand 'templates', Templates

  desc 'search NEEDLE', 'Search pre-defined paths and files'
  def search(needle)
    cmd = Search.new.search(needle)
    results = run(cmd, capture: true)
    puts results
  end
end

App.start(ARGV)
