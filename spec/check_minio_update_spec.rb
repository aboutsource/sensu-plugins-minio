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
      body: '3832278ee2bb74d41b617788b4244e410b29e4a8 minio.RELEASE.2022-07-17T15-43-14Z', # rubocop:disable Layout/LineLength
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
    'minio version RELEASE.2022-07-17T15-43-14Z (commit-id=1b339ea062b423f1c6fbeb02116d020d18418917)' # rubocop:disable Layout/LineLength
  end

  let(:stderr) { nil }
  let(:success) { true }

  context 'with matching local and remote version' do
    it 'should be ok' do
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
          'minio.RELEASE.3022-07-17T15-43-14Z',
        status: 200
      }
    end

    it 'should be critical' do
      expect { check.run }.to raise_error do |error|
        expect(error).to be_a SystemExit
        expect(error.status).to eq 2
      end

      expect(check).to have_received(:output).with(
        'New minio version available RELEASE.3022-07-17T15-43-14Z'
      )

      expect(checksum_request).to have_been_requested
    end
  end

  context 'with unknown local version' do
    context 'when minio executable not found' do
      let(:stdout) { nil }
      let(:stderr) { 'minio not found' }
      let(:success) { false }

      it 'should be unknown' do
        expect { check.run }.to raise_error do |error|
          expect(error).to be_a SystemExit
          expect(error.status).to eq 3
        end

        expect(check).to have_received(:output).with(
          'Unable to gather local minio version: minio not found'
        )

        expect(checksum_request).not_to have_been_requested
      end
    end

    context 'when release could not be extracted' do
      let(:stdout) { 'INVALID' }

      it 'should be unknown' do
        expect { check.run }.to raise_error do |error|
          expect(error).to be_a SystemExit
          expect(error.status).to eq 3
        end

        expect(check).to have_received(:output).with(
          'Unable to extract release: INVALID'
        )

        expect(checksum_request).not_to have_been_requested
      end
    end
  end

  context 'with unknown remote version' do
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

    context 'when release could not be extracted' do
      let(:response) do
        {
          body: '3832278ee2bb74d41b617788b4244e410b29e4a8 INVALID',
          status: 200
        }
      end

      it 'should be unknown' do
        expect { check.run }.to raise_error do |error|
          expect(error).to be_a SystemExit
          expect(error.status).to eq 3
        end

        expect(check).to have_received(:output).with(
          'Unable to extract release: 3832278ee2bb74d41b617788b4244e410b29e4a8 INVALID' # rubocop:disable Layout/LineLength
        )

        expect(checksum_request).to have_been_requested
      end
    end
  end
end
