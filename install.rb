#!/usr/bin/env ruby

# frozen_string_literal: true

require 'thor'       # the main CLI framework
require 'ostruct'    # for creating erb namespace
require 'erb'        # for generating file from erb
require 'io/console' # for single char input (getch)

# :reek:TooManyMethods { max_methods: 20 }

# The Install class drives installation of MyCLI.
class Install < Thor
  include Thor::Actions

  class_option :dryrun, type: :boolean

  def self.exit_on_failure?
    true
  end

  desc 'install', 'Install MyCLI'
  def install
    ns.mycli_repo_path = __dir__

    if options[:dryrun]
      say 'Installing in DryRun mode...'
    else
      say 'Installing...'
    end

    handle_name
    handle_ruby_version
    generate_files
    final_words
  end
  default_task :install

  private

  def ns
    @ns ||= OpenStruct.new
  end

  def print_header(str)
    print "\n"
    say set_color(str, :green, :bold)
  end

  def generate_files
    generate_m_script
    generate_config_yaml
    generate_output_directory
  end

  def generate_m_script
    user_exec_path = request_user_exec_path
    request_retry_on_error

    template_filepath = File.join(__dir__, 'm.erb')
    target_filepath = File.join(user_exec_path, 'm')
    ns.m_filepath = target_filepath
    generate_file(template_filepath, target_filepath, 0o0755)
  end

  def generate_config_yaml
    template_filepath = File.join(__dir__, 'config.yaml.erb')
    target_filepath = File.join(__dir__, 'config.yaml')
    generate_file(template_filepath, target_filepath, 0o0644)
  end

  def generate_output_directory
    mycli_output_dir = File.join(__dir__, 'examples', 'output')
    Dir.mkdir(mycli_output_dir) unless File.exist?(mycli_output_dir) || options[:dryrun]
  end

  # Returns true if Y/y is typed, false otherwise.
  # Considers the default valued typed if no input is provided.
  def yes_no?(msg, default = 'y')
    print msg
    ans = $stdin.getch.strip.downcase
    ans = default if ans.empty?
    puts ans
    ans.start_with?('y')
  end

  def handle_ruby_version
    print_header 'Ruby version'

    puts "You are currently using Ruby version #{RUBY_VERSION}."
    say 'The Thor gem seems to be here so I will use this version to run MyCLI in the future.'
    yn = yes_no?('Is that okay with you? [Yn]')
    unless yn
      msg = set_color('Okay... maybe try again later then.', :yellow)
      raise Thor::Error, msg
    end
    ns.ruby_version = RUBY_VERSION
  end

  def handle_name
    print_header 'Full name'

    name = ''
    while name.strip.empty?
      name = ask 'What is your full name (used for author name in templating, etc.)?'
      name.strip!
    end
    parts = name.split
    ns.full_name = name
    ns.first_name = parts.shift
    ns.last_name  = parts.join(' ')
    puts "Okay #{ns.first_name}, let's get started!"
  end

  def request_retry_on_error
    print_header 'Experimental feature'

    say <<~ENDSAY.strip
      The MyCLI wrapper script has an experimental feature that changes how it
      handles errors from Thor. If you turn this feature on it will retry with
      the command with the first parameter expanded with spaces.

      For example, if 'm tcb bob' fails it will retry with 'm t c b bob'.

      WARNING: This will retry in this way on ANY error, not just
      command not found.
    ENDSAY

    retry_on_error = yes_no?("\nWould you like to turn this feature on? [yN]", 'n')
    ns.retry_on_error = (retry_on_error ? 1 : 0)
  end

  def request_user_exec_path
    print_header 'User path directory'

    say <<~ENDSAY.strip
      We need to find a place to put your 'm' wrapper script.
      If you provide a directory in your path, we can put it there.
      Otherwise, we will put it in the MyCLI directory and you can
      create an alias to it later.
    ENDSAY
    find_dir = yes_no?("\nWould you like to provide a directory? [Yn]")

    user_dir = __dir__
    if find_dir
      user_dir = request_directory
    end

    say "Okay. We'll use #{user_dir}"
    user_dir
  end

  def request_directory
    user_dir = ask_for_user_directory

    until File.directory?(user_dir)
      try_again = yes_no? 'Hmm... that doesn\'t look like a directory. Try again? [Yn]'
      unless try_again
        user_dir = __dir__
        break
      end
      user_dir = ask_for_user_directory
    end

    user_dir
  end

  def ask_for_user_directory
    user_dir = ask 'Cool. What directory would you like to use?'
    File.expand_path(user_dir)
  end

  def apply_erb(text, namespace)
    ERB.new(text).result(namespace.instance_eval { binding })
  end

  def generate_file(template_filepath, target_filepath, permissions = 0o0644)
    print_header "Generate #{target_filepath} with ERB..."

    template_raw = File.read(template_filepath)
    result = apply_erb(template_raw, ns)

    if options[:dryrun]
      puts "perms = #{permissions.to_s(8)}; umask = #{File.umask}"
      puts result
    else
      File.open(target_filepath, 'w+', permissions) do |file|
        file.write(result)
      end
    end
  end

  def final_words
    print_header 'Final words'
    say <<~ENDSAY.strip
      Your wrapper script `m` and `config.yaml` files have been generated!
      Your initial `config.yaml` file points to files in `./examples`
      and writes any output files to `./examples/output`.

      Please check out the README.md and try the examples listed there.
      Then check out `./config.yaml` and make it your own.
    ENDSAY

    say set_color("\nEnjoy!", :green)
  end
end

Install.start(ARGV)
