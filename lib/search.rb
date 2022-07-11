require 'thor'       # the main CLI framework
require 'erb'        # templating system
require 'ostruct'    # to provide limited binding context to erb
require 'all'        # include all the local things

class MalformedConfig < StandardError
end

class Search
  attr_reader :options

  def search(needle, options)
    @options = options
    search_commands(needle)
  end

  private

  # searches deeply in the hash for arrays of strings
  def each_array_of_strings(hash, &_block)
    stack = hash.map { |k, v| [[k], v] }
    until stack.empty?
      path, value = stack.pop
      array_of_strings = (value.is_a?(Array) && value.all?(String))

      yield(path, value) if array_of_strings

      if value.is_a? Hash
        value.each { |k, v| stack.push [path.dup << k, v] }
      elsif value.is_a?(Array) && !array_of_strings
        err = 'Only paths (strings) are allowed in arrays for search config!'
        raise MalformedConfig, err
        # value.each { |v| stack.push [path.dup << :array, v] }
      end
    end
  end

  def update_combined_meta(combined_meta, meta)
    return unless meta.is_a? Hash

    if meta.key? :add_arguments
      new_args = meta.delete :add_arguments
      combined_meta[:arguments] = [combined_meta[:arguments], new_args].compact.join(' ')
    end

    combined_meta.merge!(meta)
  end

  def build_combined_meta(path)
    combined_meta = {}

    (1..path.size).each do |i|
      if config.dig(*path[0...i]).is_a? Hash
        meta = config.dig(*path[0...i], :meta)
        update_combined_meta(combined_meta, meta)
      end
    end

    combined_meta
  end

  def search_commands(needle)
    puts "Search options: #{options}" if options[:verbose]
    cmds = []

    each_array_of_strings(config) do |path, value|
      next if options[:group] && !path.include?(options[:group].to_sym)

      meta = build_combined_meta(path)
      exec = meta[:executable] || 'rg'
      search_options = options[:options] || meta[:arguments] || ''
      paths = value.join(' ')
      search_term = needle
      if meta[:search_template]
        search_term = apply_erb(meta[:search_template], {search_term: needle})
      end
      cmd = "#{exec} #{search_options} \"#{search_term}\" #{paths}"
      cmds << cmd

      if options[:verbose]
        puts '----------------------------------'
        puts "path:  #{path}"
        puts "value: #{value}"
        puts "meta:  #{meta}"
        puts "cmd:   #{cmd}"
        puts '----------------------------------'
      end
    end

    if options[:verbose]
      puts '----- cmds ------'
      pp cmds
      puts '----- cmds.uniq ------'
      pp cmds.uniq
    end

    cmds.uniq
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
