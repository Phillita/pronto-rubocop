# frozen_string_literal: true

require 'spec_helper'

describe Pronto::Rubocop::OffenseLine do
  let(:offense_line) { described_class.new(patch_cop, offense, line) }
  let(:patch_cop) { instance_double Pronto::Rubocop::PatchCop, runner: runner }
  let(:runner) do
    instance_double Pronto::Rubocop, pronto_rubocop_config: config
  end
  let(:offense) do
    instance_double RuboCop::Cop::Offense,
                    severity: severity,
                    message: 'Fake message',
                    location: offense_location
  end
  let(:offense_location) { double :location, first_line: 42, last_line: 43 }
  let(:line) do
    instance_double Pronto::Git::Line, patch: patch, commit_sha: 'af42', new_lineno: 42
  end
  let(:patch) { instance_double Pronto::Git::Patch, delta: delta }
  let(:delta) { instance_double Rugged::Diff::Delta, new_file: new_file }
  let(:new_file) { { path: 'example.rb' } }
  let(:severity) { instance_double RuboCop::Cop::Severity, name: severity_name }
  let(:severity_name) { :refactor }
  let(:config) { {} }

  describe '#message' do
    let(:message) { offense_line.message }

    it { expect(message.path).to eq('example.rb') }
    it { expect(message.line).to eq(line) }
    it { expect(message.msg).to eq('Fake message') }

    context 'with default severity levels' do
      default_level_hash = {
        refactor: :warning,
        convention: :warning,
        warning: :warning,
        error: :error,
        fatal: :fatal
      }
      default_level_hash.each do |given_severity, expected_level|
        context "when severity is #{given_severity}" do
          let(:severity_name) { given_severity }

          it "has a #{expected_level} level" do
            expect(message.level).to eq(expected_level)
          end
        end
      end
    end

    context 'with overridden severity levels to "fatal"' do
      let(:config) do
        {
          'severities' =>
            RuboCop::Cop::Severity::NAMES.map { |name| [name, 'fatal'] }.to_h
        }
      end

      RuboCop::Cop::Severity::NAMES.each do |given_severity|
        context "when severity is #{given_severity.inspect}" do
          let(:severity_name) { given_severity }

          it 'has the overridden level' do
            expect(message.level).to eq(:fatal)
          end
        end
      end
    end

    context 'when the offense is indirectly related to the new code' do
      let(:offense_location) { double :location, first_line: 40, last_line: 41 }

      it 'includes the indirect message' do
        expect(message.msg).to include('Offense generated for line 40:')
      end
    end
  end
end
