# frozen_string_literal: true

require 'thor'       # the main CLI framework
require 'net/http'   # for fetching remote template data set
require 'uri'        # for fetching remote template data set
require 'erb'        # templating system
require 'ostruct'    # to provide limited binding context to erb
require 'date'       # for erb binding context date value
require 'fileutils'  # for read/write of templates
require 'config'

# Templates defines Thor tasks to create new files from templates.
class Templates < Thor
  include Thor::Actions

  attr_reader :template_filepath, :target_path, :config, :namespace

  desc 'create TEMPLATE BASENAME', 'create new file from template'
  long_desc <<-LONGDESC
    `m create` will create a new file from a specified template.

    If the template file has a '.erb' extension it is treated like an ERB
    template. Template namespace details (data available to an ERB template) are
    specified in the MyCLI `config.yaml` configuration file. See
    `config.yaml.erb` or your newly created `config.yaml` file for details.

    If the template file does not have a '.erb' extension it will simply be
    copied to the target location.

    Examples:

    > $ m create zet how-to-eat-dessert

    See also: `m templates list` for a list of defined templates
  LONGDESC
  option :key
  def create(template_name, basename)
    # @namespace holds variables/keys we eventually pass
    # as the binding context to ERB.
    @namespace = {}
    template_name = resolve_template_name(template_name)
    # @config holds the config.yaml subtree for the specified template
    @config = find_valid_config(template_name)
    @template_filepath = find_valid_filepath(config[:filepath])
    @target_path = find_valid_directory(config.dig(:target, :path))

    populate_namespace_with_config_values
    populate_namespace_with_generated_values(template_name, basename)

    create_file
  end

  desc 'list', 'List all templates'
  def list
    unless templates
      puts set_color('No available templates.', :green, :bold)
      return
    end

    puts set_color("Available templates:\n", :green, :bold)
    shell = Thor::Shell::Basic.new
    table = build_table
    shell.print_table(table, indent: 2)
  end

  private

  # :reek:FeatureEnvy
  def build_table
    table = [['Name', 'Source path', 'Target path', 'Suffix', 'Prefix'],
             ['----', '-----------', '-----------', '------', '------']]

    templates.each do |name, config|
      target = config[:target]
      table << [
        name,
        config[:filepath],
        target[:path],
        target[:suffix],
        target[:prefix]
      ]
    end

    table
  end

  def templates
    MyCLI::Config.instance.data.dig(:commands, :templates, :create)
  end

  def globals
    MyCLI::Config.instance.data[:globals]
  end

  def apply_erb(text)
    erb_namespace = OpenStruct.new(namespace)
    ERB.new(text).result(erb_namespace.instance_eval { binding })
  end

  def expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV.fetch($1) }
  end

  def find_valid_config(template_name)
    template_config = templates[template_name]
    unless template_config
      msg = set_color("No \"#{template_name}\" template was found.", :yellow)
      raise Thor::Error, msg
    end

    template_config
  end

  def populate_namespace_with_config_values
    populate_namespace_with_predefined
    populate_namespace_with_keyed_set
    populate_namespace_with_prompt_for
  end

  def populate_namespace_with_generated_values(template_name, basename)
    namespace[:today]             = Date.today.strftime('%Y-%m-%d')
    namespace[:template_name]     = template_name
    namespace[:basename]          = basename
    namespace[:title]             = basename.tr('-_', ' ').capitalize
    namespace[:target_filename]   = nil # set later after computed
    namespace[:full_name]         = globals[:full_name]
    namespace[:template_filepath] = template_filepath

    target_filename = build_target_filename(basename)
    target_filepath = File.join(target_path, target_filename)
    namespace[:target_filename] = target_filename
    namespace[:target_filepath] = target_filepath
  end

  def populate_namespace_with_predefined
    namespace.merge!(config.dig(:namespace, :predefined) || {})
  end

  def populate_namespace_with_keyed_set
    keyed_set = config.dig(:namespace, :keyed_set)
    return unless keyed_set

    key = find_valid_key(keyed_set)

    if options[:verbose]
      puts "options[:key] = #{options[:key]}"
      puts "keyed_set[:key] = #{keyed_set[:key]}"
      puts "computed key = #{key}"
    end

    # check set_data for url
    keyed_data = if keyed_set[:set_data].is_a? String
                   fetch_remote_set_data(keyed_set, key)
                 else
                   keyed_set.dig(:set_data, key.to_sym)
                 end

    if keyed_data
      namespace.merge!(keyed_data)
    else
      msg = set_color('Key not found in data set!', :red)
      raise Thor::Error, msg
    end
  end

  def find_valid_key(keyed_set)
    key = options[:key] || keyed_set[:key]
    unless key
      prompt_default = 'Enter key for keyed set'
      key_prompt = keyed_set[:key_prompt] || prompt_default
      key = ask key_prompt
      msg = set_color('Key for data set is required!', :red)
      raise Thor::Error, msg if key.to_s.empty?
    end
    key
  end

  # :reek:FeatureEnvy
  def fetch_remote_set_data(keyed_set, key)
    address = keyed_set[:set_data]
    uri = URI.parse(address)
    response = Net::HTTP.get_response uri
    if response.code != '200'
      raise Thor::Error, "Failed to fetch remote data from #{address}"
    end

    set_data = YAML.safe_load(
      response.body,
      aliases: true,
      symbolize_names: true
    )
    set_data[key.to_sym]
  end

  def populate_namespace_with_prompt_for
    prompt_for = config.dig(:namespace, :prompt_for)
    return unless prompt_for

    prompt_for.each do |prompt_data|
      var_name = prompt_data[:var_name]
      next unless var_name

      prompt = prompt_data[:prompt] || "Value for #{var_name}"
      value = ask prompt, default: prompt_data[:default]
      namespace[var_name.to_sym] = value
    end
  end

  def find_valid_directory(directory)
    candidate = File.expand_path(expand_env(directory))

    unless File.directory?(candidate)
      msg = set_color("Directory not found: #{candidate}", :yellow)
      raise Thor::Error, msg
    end

    candidate
  end

  def find_valid_filepath(filepath)
    candidate = File.expand_path(expand_env(filepath))

    unless File.file?(candidate)
      msg = set_color("File not found: #{candidate}", :yellow)
      raise Thor::Error, msg
    end

    candidate
  end

  def resolve_template_name(template_name)
    possibles = templates.keys.filter { |key| key.start_with?(template_name) }

    case possibles.size
    when 0
      msg = set_color("Template not found: #{template_name}", :yellow)
    when 2..Float::INFINITY
      msg = set_color("Template name is not unique: #{template_name}", :yellow)
    end

    raise Thor::Error, msg if msg

    possibles.first
  end

  def build_target_filename(basename)
    target = config[:target]

    target_suffix_raw = target[:suffix] || ''
    target_suffix = apply_erb(target_suffix_raw)

    target_prefix_raw = target[:prefix] || ''
    target_prefix = apply_erb(target_prefix_raw)

    target_prefix + basename + target_suffix
  end

  def create_file
    template = namespace[:template_name]
    target = namespace[:target_filepath]
    puts set_color("Creating new #{template} file as #{target} ...", :green)

    if File.extname(namespace[:template_filepath]) == '.erb'
      create_file_from_erb
    else
      create_file_from_copy
    end
  end

  def create_file_from_erb
    perms = config[:target][:permissions]&.to_i(8) || 0o644

    template_raw = File.read(namespace[:template_filepath])
    result = apply_erb(template_raw)
    File.open(namespace[:target_filepath], 'w+', perms) do |file|
      file.write(result)
    end

    if options[:verbose]
      puts 'Filtered file copy through ERB'
      puts "perms = #{perms}, #{perms.to_s(8)}, #{perms.class}; umask = #{File.umask}"
      puts result
    end
  end

  def create_file_from_copy
    puts 'FileUtils.copy_file'
    FileUtils.copy_file(
      namespace[:template_filepath],
      namespace[:target_filepath],
      preserve: true
    )
  end
end
