require 'singleton'
require 'yaml'
require 'pp'

module MyCLI
  class Config
    include Singleton

    attr_accessor :data

    CONFIG_FILE = "#{__dir__}/../config.yaml".freeze

    def initialize
      @data = YAML.safe_load_file(CONFIG_FILE, aliases: true)
    end

    def show
      puts 'MyCLI::Config data:'
      pp @data
    end
  end
end
