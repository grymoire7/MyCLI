# frozen_string_literal: true

require 'spec_helper'
require 'search'

RSpec.describe Search do
  let(:config) { MyCLI::Config.instance }

  it 'existentialism' do
    expect(subject).not_to be_nil
  end

  it 'fake search' do
    allow(subject).to receive(:search).and_return(%w(one two))
    expect(subject.search(:one, :two)).to eq(%w(one two))
  end
end
