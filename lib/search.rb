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
      value_is_array = value.is_a?(Array)
      array_of_strings = (value_is_array && value.all?(String))

      yield(path, value) if array_of_strings

      if value.is_a? Hash
        value.each { |key, val| stack.push [path.dup << key, val] }
      elsif value_is_array && !array_of_strings
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

  def search_commands(needle)
    puts "Search options: #{options}" if verbose
    cmds = []
    group = options[:group]

    each_array_of_strings(config) do |config_path, path_strings|
      next if group && !config_path.include?(group.to_sym)

      cmd = build_command(needle, config_path, path_strings)
      cmds << cmd
    end

    cmds.uniq!
    cmds
  end

  def build_command(needle, config_path, path_strings)
    meta = build_combined_meta(config_path)
    exec = meta[:executable] || 'rg'
    search_options = options[:options] || meta[:arguments] || ''
    search_term = build_search_term(needle, meta)
    path_string = path_strings.join(' ')

    "#{exec} #{search_options} \"#{search_term}\" #{path_string}"
  end

  def build_search_term(needle, meta)
    search_term = needle
    search_template = meta[:search_template]
    if search_template
      search_term = apply_erb(search_template, { search_term: needle })
    end
    search_term
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
