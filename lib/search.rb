require 'thor'       # the main CLI framework
require 'all'        # include all the local things

class Search
  attr_reader :c

  def search(needle, options)
    search_command(needle, options)
  end

  private

  # Find all unique leaf values in a nested structure from yaml file.
  #
  # We assume only Hash and Array enumerables since input comes from a
  # parsed yaml file.
  #
  # h = {
  #   numbers: [1, 2, [3, 4, 2, [8, 9]], 5, nil],
  #   ahash: {
  #     one: 'one',
  #     two: 'two',
  #     three: 'three',
  #     nested_array: [101, 102, [102, 103]]
  #   },
  #   anumber: 999,
  #   astring: 'Howdy!'
  # }
  #
  # pp find_all_values(h)
  # => [1, 2, 3, 4, 8, 9, 5, "one", "two", "three", 101, 102, 103, 999, "Howdy!"]
  #
  # Note: This is overkill for our purposes... but fun to write.
  #
  def find_all_values(structure)
    unless structure.is_a?(Array) || structure.is_a?(Hash)
      return [structure]
    end

    structure = structure.values if structure.is_a? Hash

    structure.map{ |elt| find_all_values(elt) }.flatten.uniq.compact
  end

  # returns an array of objects found at all instances of a given key in a
  # nested hash, and the found objects transformed with #find_all_values
  #
  # object = {
  #   projects: {
  #     apple: {
  #       code: ["~/projects/apple/app", "~/projects/apple/lib"],
  #       docs: ["~/projects/apple/README.md", "~/projects/apple/docs"]
  #     },
  #     orange: {
  #       code: ["~/projects/orange/app", "~/projects/orange/lib"],
  #       docs: ["~/projects/orange/README.md", "~/projects/orange/docs"]
  #     }
  #   }
  # }
  # pp deep_find(object, :docs)
  # => [ "~/projects/apple/README.md",
  #      "~/projects/apple/docs",
  #      "~/projects/orange/README.md",
  #      "~/projects/orange/docs"]
  #
  # pp deep_find(object, :apple)
  # => [ "~/projects/apple/app",
  #      "~/projects/apple/lib",
  #      "~/projects/apple/README.md",
  #      "~/projects/apple/docs"]
  #
  def deep_find(object, key)
    found = []
    if object.respond_to?(:key?) && object.key?(key)
      found << find_all_values(object[key])
    end
    if object.is_a? Enumerable
      found << object.map { |*a| deep_find(a.last, key) }
    end
    found.flatten.uniq.compact
  end

  def search_paths(options)
    return [] if config['paths'].nil?

    if options[:group].nil?
      paths = find_all_values(config['paths'])
    else
      paths = deep_find(config['paths'], options[:group])
    end

    paths
  end

  def search_command(needle, options)
    puts "Search options: #{options}"

    exec = config['executable'] || 'rg'
    search_options = options[:options] || config['arguments'] || ''
    paths = search_paths(options)
    # paths = search_paths(options).map{|s| "\"#{s}\""}

    puts "----- search_paths ------"
    pp paths
    "#{exec} #{search_options} \"#{needle}\" #{paths.join(' ')}"
  end

  def config
    MyCLI::Config.instance.data['commands']['search']
  end
end
