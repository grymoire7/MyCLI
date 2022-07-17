# frozen_string_literal: true

require 'spec_helper'
require 'search'

RSpec.describe Search do
  context '#search puts' do
    let(:needle) { 'puts' }
    let(:cmds) { subject.search(needle, {}) }

    it 'returns eight commands' do
      expect(cmds.size).to eq(8)
    end

    it { expect(cmds).to all((be_a(String).and include(needle))) }
    it { expect(cmds).to all((be_a(String).and include('MYCLI_EXAMPLES'))) }
  end

  context '#search example with group' do
    let(:needle) { 'example' }
    let(:cmds) { subject.search(needle, { group: 'org_heads' }) }

    it 'returns only one command' do
      expect(cmds.size).to eq(1)
    end

    it { expect(cmds).to all((be_a(String).and include(needle))) }
    it { expect(cmds).to all((be_a(String).and include('MYCLI_EXAMPLES'))) }
  end

  context '#search example search options' do
    let(:needle) { 'example' }
    let(:options) { '--foo --bar' }
    let(:cmds) { subject.search(needle, { options: options }) }

    it 'returns eight commands' do
      expect(cmds.size).to eq(8)
    end

    it { expect(cmds).to all((be_a(String).and include(needle))) }
    it { expect(cmds).to all((be_a(String).and include(options))) }
    it { expect(cmds).to all((be_a(String).and include('MYCLI_EXAMPLES'))) }
  end
end
