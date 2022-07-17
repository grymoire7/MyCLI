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
      expectation.to output(%r(examples/output/bob)).to_stdout
    end

    it 'creates a python file' do
      expectation = expect { Templates.new.invoke(:create, %w(python fred)) }
      expectation.to output(/Creating new python file/).to_stdout
      expectation.to output(%r(examples/output/fred)).to_stdout
    end
  end
end
