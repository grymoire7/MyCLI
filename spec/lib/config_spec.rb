# frozen_string_literal: true

require 'spec_helper'
require 'config'

RSpec.describe MyCLI::Config do
  let(:config) { MyCLI::Config.instance }

  # required for config to work
  it 'spec_helper has MYCLI_EXAMPLES env' do
    repo_dir = File.expand_path('../../examples/', __dir__)
    expect(ENV.fetch('MYCLI_EXAMPLES')).to eq(repo_dir)
  end

  it 'config singleton exists' do
    expect(config).not_to be_nil
  end

  it 'has expected names' do
    expect(config.data[:globals][:first_name]).to eq('Devin')
    expect(config.data[:globals][:last_name]).to eq('Devmeister')
  end

  it 'has search config' do
    expect(config.data[:commands][:search]).not_to be_nil
  end

  it 'has templates config' do
    expect(config.data[:commands][:templates]).not_to be_nil
  end
end
