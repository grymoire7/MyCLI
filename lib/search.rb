require 'thor'       # the main CLI framework
require 'all'        # include all the local things

class Search

  attr_reader :c

  def search(needle, options={})
    search_command(needle)
  end

  private

  def search_path
    return @search_path if @search_path
    @search_path = config['paths'] || ['.']
  end

  def search_command(needle)
    return @search_command if @search_command
    exec = config['executable'] || 'rg'
    options = config['arguments'] || ''
    @search_command = "#{exec} #{options} \"#{needle}\" #{search_path.join(' ')}"
  end

  def config
    MyCLI::Config.instance.data['commands']['search']
  end

end
