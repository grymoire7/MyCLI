#!/usr/bin/env ruby

# frozen_string_literal: true

# In help we want to refer to the program as 'm' instead of 'm.rb'
# and in other places we want syntax highlighting.
$PROGRAM_NAME = 'm'

$LOAD_PATH << File.join(__dir__, 'lib')

require 'thor'       # the main CLI framework
require 'all'        # include all the local things

class App < Thor
  include Thor::Actions

  class_option :verbose, type: :boolean

  @exit_on_failure = true

  def self.exit_on_failure?
    @@exit_on_failure
  end

  desc 'howdy', 'Say howdy'
  subcommand 'howdy', Howdy

  desc 'templates', 'List top all templates'
  subcommand 'templates', Templates

  desc 'search NEEDLE', 'Search pre-defined paths and files'
  option :options, aliases: :o, banner: '<search options>'
  option :group, aliases: :g, banner: '<path group>'
  def search(needle)
    @exit_on_failure = false
    cmds = Search.new.search(needle, options)
    cmds.each do |cmd|
      results = run(cmd, capture: true)
      puts results
    end
  end
end

App.start(ARGV)
