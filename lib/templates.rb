# frozen_string_literal: true

require 'thor'       # the main CLI framework
require 'net/http'   # for fetching remote template data set
require 'uri'        # for fetching remote template data set
require 'erb'        # templating system
require 'ostruct'    # to provide limited binding context to erb
require 'date'       # for erb binding context date value
require 'fileutils'  # for read/write of templates
require 'template_config' # configuration to namespace
require 'config'

# Templates defines Thor tasks to create new files from templates.
class Templates < Thor
  include Thor::Actions

  attr_reader :config, :namespace

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
    template_name = resolve_template_name(template_name)
    template_config = TemplateConfig.new(template_name, basename, options)

    # @config holds the config.yaml subtree for the specified template
    @config = template_config.config

    # @namespace holds variables/keys we eventually pass
    # as the binding context to ERB.
    @namespace = template_config.namespace

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

  def apply_erb(text)
    erb_namespace = OpenStruct.new(namespace)
    ERB.new(text).result(erb_namespace.instance_eval { binding })
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

    # rubocop:disable Style/GuardClause
    if options[:verbose]
      puts 'Filtered file copy through ERB'
      puts "perms = #{perms}, #{perms.to_s(8)}, #{perms.class}; umask = #{File.umask}"
      puts result
    end
    # rubocop:enable Style/GuardClause
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
