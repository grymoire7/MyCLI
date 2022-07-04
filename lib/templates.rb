require 'thor'       # the main CLI framework
require 'erb'        # templating system
require 'ostruct'    # to provide limited binding context to erb
require 'date'       # for erb binding context date value
require 'fileutils'  # for read/write of templates
require 'all'        # include all the local things

class Templates < Thor
  include Thor::Actions

  desc "create TEMPLATE BASENAME", "create new file from template"
  long_desc <<-LONGDESC
    `m create` will create a new file from a specified template.

    Template details, including name, template location, target location,
    etc., are specified in the MyCLI `config.yaml` configuration file.
    If the template file has a '.erb' extension it is treated like an
    ERB template with the following variables available:

    \x5  today............... Date.today.strftime('%Y-%m-%d')
    \x5  template_name....... the template's short name, e.g. 'bash'
    \x5  target_filename..... the fileaname being written (no path)
    \x5  user_name........... the 'name' defined in config globals
    \x5  template_filepath... the full template filepath

    Additional variables may be provided to the template namespace
    through the `namespace_data` key for a template in config.yaml.

    Examples:

    > $ m create zet how-to-eat-dessert

    See also: `m templates list` for a list of defined templates
  LONGDESC
  option :subkey
  def create(template_name, basename)
    template_name = resolve_template_name(template_name)
    config = templates[template_name]
    validate_template(template_name)

    template_filepath = File.expand_path(config['filepath'])
    target_path = File.expand_path(config['target']['path'])

    namespace = config_namespace(config, options[:subkey])
    namespace.today             = Date.today.strftime('%Y-%m-%d')
    namespace.template_name     = template_name
    namespace.target_filename   = nil  # set later after computed
    namespace.author            = globals['name']
    namespace.template_filepath = template_filepath

    target_filename = build_target_filename(config, basename, namespace)
    target_filepath = File.join(target_path, target_filename)
    namespace.target_filename = target_filename
    namespace.target_filepath = target_filepath

    puts set_color("Creating new #{template_name} file as #{target_filepath} ...", :green)

    create_file(config, namespace)
  end

  desc "list", "List all templates"
  def list
    puts set_color("Available templates:\n", :green, :bold)
    shell = Thor::Shell::Basic.new
    table = [['Name', 'Source path', 'Target path', 'Suffix', 'Prefix'],
             ['----', '-----------', '-----------', '------', '------']]
    templates.each do |name, config|
      table << [
        name,
        config['filepath'],
        config['target']['path'],
        config['target']['suffix'],
        config['target']['prefix']
      ]
    end
    shell.print_table(table, indent: 2)
  end

  private

  def templates
    MyCLI::Config.instance.data['commands']['create']['templates']
  end

  def globals
    MyCLI::Config.instance.data['globals']
  end

  def apply_erb(text, namespace)
    ERB.new(text).result(namespace.instance_eval { binding })
  end

  def validate_template(template_name)
    config = templates[template_name]

    if config == nil
      msg = set_color("No \"#{template_name}\" template was found.", color=:yellow)
      raise Thor::Error.new(msg)
    end

    template_filepath = File.expand_path(config['filepath'])
    target_path = File.expand_path(config['target']['path'])

    # bail if template_filepath does not exist
    unless File.file?(template_filepath)
      msg = set_color("File not found: #{template_filepath}", color=:yellow)
      raise Thor::Error.new(msg)
    end

    # bail if target_path does not exist
    unless File.directory?(target_path)
      msg = set_color("Directory not found: #{target_path}", color=:yellow)
      raise Thor::Error.new(msg)
    end
  end

  def resolve_template_name(template_name)
    possibles = templates.keys.filter{ |k| k.start_with?(template_name) }
    case possibles.size
    when 0
      msg = set_color("Template not found: #{template_name}", color=:yellow)
      raise Thor::Error.new(msg)
    when 2..Float::INFINITY
      msg = set_color("Template name is not unique: #{template_name}", color=:yellow)
      raise Thor::Error.new(msg)
    end
    possibles.first
  end

  def config_namespace(config, subkey)
    namespace_data = config['namespace_data']

    if namespace_data
      default_subkey = config['namespace_subkey']

      if options[:subkey] && namespace_data[subkey]
        subkey_data = namespace_data[subkey]
      else
        subkey_data = namespace_data[default_subkey]
      end
      namespace_data = subkey_data if subkey_data
    end

    OpenStruct.new(namespace_data || {})
  end

  def build_target_filename(config, basename, namespace)
    target_suffix_raw = config['target']['suffix'] || ''
    target_suffix = apply_erb(target_suffix_raw, namespace)

    target_prefix_raw = config['target']['prefix'] || ''
    target_prefix = apply_erb(target_prefix_raw, namespace)

    target_prefix + basename + target_suffix
  end

  def create_file(config, ns)
    # filter file with ERB if extension is .erb
    if File.extname(ns.template_filepath) == '.erb'
      perms = config['target']['permissions']&.to_i(8) || 0644
      puts "Filter file copy through ERB"
      puts "perms = #{perms}, #{perms.to_s(8)}, #{perms.class}; umask = #{File.umask}"

      template_raw = File.read(ns.template_filepath)
      result = apply_erb(template_raw, ns)
      File.open(ns.target_filepath, 'w+', perms) do |f|
        f.write(result)
      end
      puts result
    else
      puts "FileUtils.copy_file"
      FileUtils.copy_file(
        ns.template_filepath,
        ns.target_filepath,
        preserve: true
      )
    end
  end

end
