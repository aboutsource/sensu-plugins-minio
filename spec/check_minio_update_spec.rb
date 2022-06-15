# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../bin/check-minio-update'

CheckMinioUpdate.class_variable_set(:@@autorun, false)

describe CheckMinioUpdate do
  before do
    stub_checksum_request
    allow(check).to(receive(:output))
    allow(Open3).to(
      receive(:capture3).and_return([stdout, stderr, double(success?: success)])
    )
  end

  let(:checksum_request) do
    stub_request(
      :get,
      'https://dl.min.io/server/minio/release/linux-amd64/minio.shasum'
    ).to_return(response)
  end

  let(:response) do
    {
      body:
        '285ec90006a6961ebcb7dd9685acc0ebcd08f561 '\
        'minio.RELEASE.2021-07-08T19-43-25Z',
      status: 200
    }
  end

  alias_method :stub_checksum_request, :checksum_request

  let(:check) do
    CheckMinioUpdate.new.tap do |check|
      check.config[:checkurl] = 'https://dl.min.io/server/minio/release'
      check.config[:platform] = 'linux-amd64'
    end
  end

  let(:stdout) do
    "minio version RELEASE.2021-07-08T19-43-25Z\n"\
    "commit: dd53b287f2eeed9cd3872eeae7d64696bfd7829d\n"\
    'go version: go1.18.3'
  end
  let(:stderr) { nil }
  let(:success) { true }

  context 'with matching local and remote version' do
    it 'should be ok if versions are equal' do
      expect { check.run }.to raise_error do |error|
        expect(error).to be_a SystemExit
        expect(error.status).to eq 0
      end

      expect(check).to have_received(:output).with(
        'No new minio version available'
      )
      expect(checksum_request).to have_been_requested
    end
  end

  context 'with different local and remote versions' do
    let(:response) do
      {
        body:
          '285ec90006a6961ebcb7dd9685acc0ebcd08f561 '\
          'minio.RELEASE.2022-07-08T19-43-25Z',
        status: 200
      }
    end

    it 'should be critical' do
      expect { check.run }.to raise_error do |error|
        expect(error).to be_a SystemExit
        expect(error.status).to eq 2
      end

      expect(check).to have_received(:output).with(
        'New minio version available RELEASE.2022-07-08T19-43-25Z'
      )
      expect(checksum_request).to have_been_requested
    end
  end

  context 'with unknown local version' do
    let(:stdout) { nil }
    let(:stderr) { 'Minio not found' }
    let(:success) { false }

    it 'should be unknown' do
      expect { check.run }.to raise_error do |error|
        expect(error).to be_a SystemExit
        expect(error.status).to eq 3
      end

      expect(check).to have_received(:output).with(
        'Unable to gather local minio version: Minio not found'
      )
      expect(checksum_request).to have_been_requested
    end
  end

  context 'with release url not found' do
    let(:response) { { body: '404 Not Found', status: 404 } }

    it 'should be unknown' do
      expect { check.run }.to raise_error do |error|
        expect(error).to be_a SystemExit
        expect(error.status).to eq 3
      end

      expect(check).to have_received(:output).with(
        'Unable to gather latest minio version: 404 Not Found'
      )
      expect(checksum_request).to have_been_requested
    end
  end
end
