# frozen_string_literal: true

require 'config'
require 'thor'
require 'uri' # for fetching remote template data set
require 'erb'

# :reek:TooManyInstanceVariables

# The TemplateConfig class wrangles configuration into an ERB namespace.
class TemplateConfig
  attr_reader :template_name, :basename, :templates, :options, :shell

  def initialize(template_name, basename, options)
    @template_name = template_name
    @basename = basename
    @options = options
    @shell = Thor::Shell::Color.new
    config = MyCLI::Config.instance.data
    @templates = config.dig(:commands, :templates, :create)
  end

  def namespace
    @namespace ||= populate_namespace
  end

  def config
    @config ||= begin
      config = templates[template_name]
      unless config
        msg = shell.set_color("No \"#{template_name}\" template was found.", :yellow)
        raise Thor::Error, msg
      end

      config
    end
  end

  private

  def template_filepath
    filepath = config[:filepath]
    candidate = File.expand_path(expand_env(filepath))

    unless File.file?(candidate)
      msg = shell.set_color("File not found: #{candidate}", :yellow)
      raise Thor::Error, msg
    end

    candidate
  end

  def target_directory
    filepath = config.dig(:target, :path)
    candidate = File.expand_path(expand_env(filepath))

    unless File.directory?(candidate)
      msg = shell.set_color("Directory not found: #{candidate}", :yellow)
      raise Thor::Error, msg
    end

    candidate
  end

  def build_target_filename(namespace)
    target = config[:target]

    target_suffix_raw = target[:suffix] || ''
    target_suffix = apply_erb(target_suffix_raw, namespace)

    target_prefix_raw = target[:prefix] || ''
    target_prefix = apply_erb(target_prefix_raw, namespace)

    target_prefix + basename + target_suffix
  end

  def populate_namespace
    namespace = {}
    populate_namespace_with_predefined(namespace)
    populate_namespace_with_keyed_set(namespace)
    populate_namespace_with_prompt_for(namespace)
    populate_namespace_with_generated_values(namespace)
    namespace
  end

  def populate_namespace_with_generated_values(namespace)
    full_name = MyCLI::Config.instance.data.dig(:globals, :fullname)

    generated = {
      today:             Date.today.strftime('%Y-%m-%d'),
      template_name:     template_name,
      basename:          basename,
      title:             basename.tr('-_', ' ').capitalize,
      full_name:         full_name,
      template_filepath: template_filepath
    }
    namespace.merge!(generated)
    target_filename = build_target_filename(namespace)
    namespace[:target_filename] = target_filename
    namespace[:target_filepath] = File.join(target_directory, target_filename)
  end

  def populate_namespace_with_predefined(namespace)
    namespace.merge!(config.dig(:namespace, :predefined) || {})
  end

  def populate_namespace_with_keyed_set(namespace)
    keyed_set = config.dig(:namespace, :keyed_set)
    return unless keyed_set

    key = find_valid_key(keyed_set)

    # check set_data for url
    keyed_data = if keyed_set[:set_data].is_a? String
                   fetch_remote_set_data(keyed_set, key)
                 else
                   keyed_set.dig(:set_data, key.to_sym)
                 end

    if keyed_data
      namespace.merge!(keyed_data)
    else
      msg = shell.set_color('Key not found in data set!', :red)
      raise Thor::Error, msg
    end
  end

  # :reek:FeatureEnvy
  def populate_namespace_with_prompt_for(namespace)
    prompt_for = config.dig(:namespace, :prompt_for)
    return unless prompt_for

    prompt_for.each do |prompt_data|
      var_name = prompt_data[:var_name]
      next unless var_name

      prompt = prompt_data[:prompt] || "Value for #{var_name}"
      value = shell.ask prompt, default: prompt_data[:default]
      namespace[var_name.to_sym] = value
    end
  end

  def find_valid_key(keyed_set)
    key = options[:key] || keyed_set[:key]
    unless key
      prompt_default = 'Enter key for keyed set'
      key_prompt = keyed_set[:key_prompt] || prompt_default
      key = shell.ask key_prompt
      msg = shell.set_color('Key for data set is required!', :red)
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

  def apply_erb(text, namespace)
    erb_namespace = OpenStruct.new(namespace)
    ERB.new(text).result(erb_namespace.instance_eval { binding })
  end

  def expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV.fetch($1) }
  end
end
