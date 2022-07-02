require 'thor'

class Howdy < Thor
  include Thor::Actions

  desc "fred", "say fred"
  def fred
    puts "fred"
  end

  desc "kim", "say kim"
  def kim
    puts "kim"
  end
end
