# frozen_string_literal: true

require 'spec_helper'
require 'Templates'

RSpec.describe Templates do
  context 'run create' do
    it 'creates a bash file' do
      # expect(
      #   capture(:stdout) do
      #     Templates.new.invoke(:create, %w(bash bob))
      #   end.strip
      # ).to include('Creating new bash file', 'examples/output/bob')
      expectation = expect { Templates.new.invoke(:create, %w(bash bob)) }
      expectation.to output(/Creating new bash file/).to_stdout
      expectation.to output(%r(/tmp/bob)).to_stdout

      outfile = File.join('/tmp', 'bob')
      expect(File.exist?(outfile)).to be
      File.delete(outfile)
    end

    it 'creates a python file' do
      expectation = expect { Templates.new.invoke(:create, %w(python fred)) }
      expectation.to output(/Creating new python file/).to_stdout
      expectation.to output(%r(/tmp/fred)).to_stdout

      outfile = File.join('/tmp', 'fred.py')
      expect(File.exist?(outfile)).to be
      File.delete(outfile)
    end

    it 'creates a sprint.org file' do
      expectation = expect { Templates.new.invoke(:create, %w(sprint current)) }
      expectation.to output(/Creating new sprint file as/).to_stdout
      expectation.to output(%r(/tmp/current.org)).to_stdout

      outfile = File.join('/tmp', 'current.org')
      expect(File.exist?(outfile)).to be
      File.delete(outfile)
    end
  end

  context 'run list' do
    it 'lists available templates' do
      sprint_template  = %r( sprint\s+\$MYCLI_EXAMPLES/org/sprint.erb)
      isprint_template = %r( isprint\s+\$MYCLI_EXAMPLES/org/sprint.erb)
      zet_template     = %r( zet\s+\$MYCLI_EXAMPLES/org/zet.erb)
      bash_template    = %r( bash\s+\$MYCLI_EXAMPLES/bin/example_script.sh)
      python_template  = %r( python\s+\$MYCLI_EXAMPLES/bin/example_script.py)

      expectation = expect { Templates.new.invoke(:list) }
      expectation.to output(/Available templates/).to_stdout
      expectation.to output(sprint_template).to_stdout
      expectation.to output(isprint_template).to_stdout
      expectation.to output(zet_template).to_stdout
      expectation.to output(bash_template).to_stdout
      expectation.to output(python_template).to_stdout
      expectation.to output(%r(/tmp )).to_stdout
    end
  end
end
