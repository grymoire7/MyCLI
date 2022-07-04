#!/usr/bin/env ruby

require 'thor'       # the main CLI framework
require 'ostruct'    # for creating erb namespace
require 'erb'        # for generating file from erb
require 'io/console' # for single char input (getch)

class Install < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc "install", "Install MyCLI"
  def install
    @namespace = OpenStruct.new

    ns.mycli_repo_path = __dir__

    puts "Installing..."
    handle_name
    puts "Okay #{ns.first_name}, let's get started!"
    handle_ruby_version

    user_exec_path = request_user_exec_path
    ns.retry_on_error = (request_retry_on_error ? 1 : 0)

    # Generate m script
    template_filepath = File.join(__dir__, 'm.erb')
    target_filepath = File.join(user_exec_path, 'm')
    ns.m_filepath = target_filepath
    generate_file(template_filepath, target_filepath, permissions=0755)

    # Generate config.yaml
    template_filepath = File.join(__dir__, 'config.yaml.erb')
    target_filepath = File.join(__dir__, 'config.yaml')
    generate_file(template_filepath, target_filepath, permissions=0644)

  end
  default_task :install

  private

  def ns
    @namespace
  end

  # Returns true if Y/y is typed, false otherwise.
  # Considers the default valued typed if no input is provided.
  def yes_no?(msg, default='y')
    print msg
    ans = STDIN.getch.strip.downcase
    ans = default if ans.empty?
    y = ans.start_with?('y')
    puts "#{ans}"
    y
  end

  def handle_ruby_version
    print "\n"
    say set_color("Ruby version", :green, :bold)
    puts "You are currently using Ruby version #{RUBY_VERSION}."
    yn = yes_no?("The Thor gem seems to be here so I will use this version to run MyCLI in the future.  Is that okay with you? [Yn]")
    unless yn
      msg = set_color("Okay... maybe try again later then.", color=:yellow)
      raise Thor::Error.new(msg)
    end
    # create_file ".ruby-version" do
    #   RUBY_VERSION
    # end
    ns.ruby_version = RUBY_VERSION
  end

  def handle_name
    print "\n"
    say set_color("Full name", :green, :bold)
    name = ''
    while name.strip.empty? do
      name = ask("What is your full name (used for author name in templating, etc.)?")
      name.strip!
    end
    parts = name.split
    ns.full_name = name
    ns.first_name = parts.shift
    ns.last_name  = parts.join(' ')
    yes_no?("Hi #{ns.first_name}! Can I call you #{ns.first_name}? [Yn]")
  end

  def request_retry_on_error
    print "\n"
    say set_color("Experimental feature", :green, :bold)
    say <<~ENDSAY.strip
      The MyCLI wrapper script has an experimental feature that changes how it
      handles errors from Thor. If you turn this feature on it will retry with
      the command with the first parameter expanded with spaces.

      For example, if 'm tcb bob' fails it will retry with 'm t c b bob'.

      WARNING: This will retry in this way on ANY error, not just
      command not found.
    ENDSAY
    yes_no?("\nWould you like to turn this feature on? [yN]", deafult='n')
  end

  def request_user_exec_path
    print "\n"
    say set_color("User path directory", :green, :bold)
    say <<~ENDSAY.strip
      We need to find a place to put your 'm' wrapper script.
      If you provide a directory in your path, we can put it there.
      Otherwise, we will put it in the MyCLI directory and you can
      create an alias to it later.
    ENDSAY
    find_dir = yes_no?("Would you like to provide a directory? [Yn]")

    user_dir = __dir__
    if find_dir
      user_dir = ask "Cool. What directory would you like to use?"
      user_dir = File.expand_path(user_dir)

      until File.directory?(user_dir) do
        try_again = yes_no? "Hmm... that doesn't look like a directory. Try again? [Yn]"
        unless try_again
          user_dir = __dir__
          break
        end
        user_dir = ask "What directory would you like to use?"
        user_dir = File.expand_path(user_dir)
      end
    end

    say "Okay. We'll use #{user_dir}"
    user_dir
  end

  def apply_erb(text, namespace)
    ERB.new(text).result(namespace.instance_eval { binding })
  end

  def generate_file(template_filepath, target_filepath, permissions=0644)
    print "\n"
    say set_color("Generate #{target_filepath} with ERB...", :green, :bold)

    puts "perms = #{permissions.to_s(8)}; umask = #{File.umask}"

    template_raw = File.read(template_filepath)
    result = apply_erb(template_raw, ns)
    # File.open(target_filepath, 'w+', permissions) do |f|
    #   f.write(result)
    # end
    puts result
  end

end

Install.start(ARGV)
