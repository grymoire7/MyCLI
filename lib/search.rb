# frozen_string_literal: true

require 'thor'      # the main CLI framework
require 'erb'       # templating system
require 'ostruct'   # to provide limited binding context to erb
require 'config'

# The MalformedConfig class provides an specialize error bad config yaml.
class MalformedConfig < StandardError
end

# The Search class provides file search capabilities.
class Search
  attr_reader :options

  def search(needle, options)
    @options = options
    search_commands(needle)
  end

  private

  # searches deeply in the hash for arrays of strings
  # :reek:FeatureEnvy
  def each_array_of_strings(hash, &_block)
    stack = hash.map { |key, value| [[key], value] }

    until stack.empty?
      path, value = stack.pop
      array_of_strings = (value.is_a?(Array) && value.all?(String))

      yield(path, value) if array_of_strings

      if value.is_a? Hash
        value.each { |key, val| stack.push [path.dup << key, val] }
      elsif value.is_a?(Array) && !array_of_strings
        err = 'Only paths (strings) are allowed in arrays for search config!'
        raise MalformedConfig, err if err
      end
    end
  end

  def merge_meta(meta_main, meta_to_merge)
    return unless meta_to_merge.is_a? Hash

    if meta_to_merge.key? :add_arguments
      new_args = meta_to_merge.delete :add_arguments
      meta_main[:arguments] = [meta_main[:arguments], new_args].compact.join(' ')
    end

    meta_main.merge!(meta_to_merge)
  end

  def build_combined_meta(path)
    combined_meta = {}

    (1..path.size).each do |index|
      path_so_far = config.dig(*path[0...index])
      if path_so_far.is_a? Hash
        meta = path_so_far[:meta]
        merge_meta(combined_meta, meta)
      end
    end

    combined_meta
  end

  def verbose
    @verbose ||= options[:verbose]
  end

  # :reek:RepeatedConditional
  def search_commands(needle)
    puts "Search options: #{options}" if verbose
    cmds = []
    group = options[:group]

    each_array_of_strings(config) do |path, value|
      next if group && !path.include?(group.to_sym)

      meta = build_combined_meta(path)
      exec = meta[:executable] || 'rg'
      search_options = options[:options] || meta[:arguments] || ''
      paths = value.join(' ')
      search_term = needle
      search_template = meta[:search_template]
      if search_template
        search_term = apply_erb(search_template, { search_term: needle })
      end
      cmd = "#{exec} #{search_options} \"#{search_term}\" #{paths}"
      cmds << cmd

      # rubocop:disable Style/Next
      if verbose
        puts '=================================='
        puts "path:  #{path}"
        puts "value: #{value}"
        puts "meta:  #{meta}"
        puts "cmd:   #{cmd}"
        puts '----------------------------------'
      end
      # rubocop:enable Style/Next
    end

    cmds.uniq!

    if verbose
      puts '----- cmds ------'
      pp cmds
    end

    cmds
  end

  def apply_erb(text, namespace)
    erb_namespace = OpenStruct.new(namespace)
    ERB.new(text).result(erb_namespace.instance_eval { binding })
  end

  def config
    search_tree = MyCLI::Config.instance.data[:commands][:search]
    { search: search_tree }
  end
end
