# frozen_string_literal: true

require 'singleton'
require 'yaml'
require 'pp'

module MyCLI
  # The Config class is the single(ton) source for config information.
  class Config
    include Singleton

    attr_reader :data

    CONFIG_FILE = "#{__dir__}/../config.yaml".freeze

    def initialize
      load_config(CONFIG_FILE)
    end

    # public scope to facilitate testing
    def load_config(config_path)
      @data = {}
      return unless File.exist?(config_path)

      @data = YAML.safe_load_file(
        config_path,
        aliases: true,
        symbolize_names: true
      )
    end

    def show
      puts 'MyCLI::Config data:'
      pp data
    end
  end
end
