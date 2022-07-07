#!/usr/bin/env ruby

require 'thor'       # the main CLI framework
require 'ostruct'    # for creating erb namespace
require 'erb'        # for generating file from erb
require 'io/console' # for single char input (getch)

class Install < Thor
  include Thor::Actions

  class_option :dryrun, type: :boolean

  def self.exit_on_failure?
    true
  end

  desc 'install', 'Install MyCLI'
  def install
    @namespace = OpenStruct.new
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
    @namespace
  end

  def h1(str)
    print "\n"
    say set_color(str, :green, :bold)
  end

  def generate_files
    # Generate m script
    user_exec_path = request_user_exec_path
    request_retry_on_error

    template_filepath = File.join(__dir__, 'm.erb')
    target_filepath = File.join(user_exec_path, 'm')
    ns.m_filepath = target_filepath
    generate_file(template_filepath, target_filepath, 0o0755)

    # Generate config.yaml
    template_filepath = File.join(__dir__, 'config.yaml.erb')
    target_filepath = File.join(__dir__, 'config.yaml')
    generate_file(template_filepath, target_filepath, 0o0644)

    # Create exmaples/output directory
    mycli_output_dir = File.join(__dir__, 'examples', 'output')
    Dir.mkdir(mycli_output_dir) unless File.exists?(mycli_output_dir) || options[:dryrun]
  end

  # Returns true if Y/y is typed, false otherwise.
  # Considers the default valued typed if no input is provided.
  def yes_no?(msg, default = 'y')
    print msg
    ans = $stdin.getch.strip.downcase
    ans = default if ans.empty?
    y = ans.start_with?('y')
    puts ans
    y
  end

  def handle_ruby_version
    h1 'Ruby version'

    puts "You are currently using Ruby version #{RUBY_VERSION}."
    say 'The Thor gem seems to be here so I will use this version to run MyCLI in the future.'
    yn = yes_no?('Is that okay with you? [Yn]')
    unless yn
      msg = set_color('Okay... maybe try again later then.', :yellow)
      raise Thor::Error, msg
    end
    # create_file ".ruby-version" do
    #   RUBY_VERSION
    # end
    ns.ruby_version = RUBY_VERSION
  end

  def handle_name
    h1 'Full name'

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
    h1 'Experimental feature'

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
    h1 'User path directory'

    say <<~ENDSAY.strip
      We need to find a place to put your 'm' wrapper script.
      If you provide a directory in your path, we can put it there.
      Otherwise, we will put it in the MyCLI directory and you can
      create an alias to it later.
    ENDSAY
    find_dir = yes_no?("\nWould you like to provide a directory? [Yn]")

    user_dir = __dir__
    if find_dir
      user_dir = ask 'Cool. What directory would you like to use?'
      user_dir = File.expand_path(user_dir)

      until File.directory?(user_dir)
        try_again = yes_no? 'Hmm... that doesn\'t look like a directory. Try again? [Yn]'
        unless try_again
          user_dir = __dir__
          break
        end
        user_dir = ask 'What directory would you like to use?'
        user_dir = File.expand_path(user_dir)
      end
    end

    say "Okay. We'll use #{user_dir}"
    user_dir
  end

  def apply_erb(text, namespace)
    ERB.new(text).result(namespace.instance_eval { binding })
  end

  def generate_file(template_filepath, target_filepath, permissions = 0o0644)
    h1 "Generate #{target_filepath} with ERB..."

    puts "perms = #{permissions.to_s(8)}; umask = #{File.umask}" if options[:dryrun]

    template_raw = File.read(template_filepath)
    result = apply_erb(template_raw, ns)

    if options[:dryrun]
      puts result
    else
      File.open(target_filepath, 'w+', permissions) do |f|
        f.write(result)
      end
    end
  end

  def final_words
    h1 'Final words'
    say <<~ENDSAY.strip
      Your wrapper script `m` and `config.yaml` files have been generated!
      Your initial `config.yaml` file points to files in `./examples`
      and writes any output files to `./examples/output`.
    ENDSAY

    print "\n"
    say set_color('  # create a new bash script in ./examples/output', :green)
    say set_color('  m template bash bob # same as `m t b bob`', :white)

    print "\n"
    say set_color('  # create a new sprint .org file based on a template in ./examples/output', :green)
    say set_color('  m template sprint sarah', :white)
    say set_color('  # ^ same as `m t s sarah`', :green)

    print "\n"
    say set_color('  # search defined paths/files for text', :green)
    say set_color('  m search puts # same as `m s puts`', :white)

    print "\n"
    say set_color('  # explore the help', :green)
    say set_color('  m help', :white)

    say "\nCheck out `./config.yaml` and make it your own."
  end
end

Install.start(ARGV)
