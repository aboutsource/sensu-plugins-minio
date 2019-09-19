# frozen_string_literal: true

require 'json'
require 'webmock/rspec'

require_relative '../bin/check-minio-update.rb'

describe CheckMinioUpdate do
  let(:status) { double }
  local_version_return = "Version: 2019-09-05T23:24:38Z\nRelease-Tag: RELEASE.2019-09-05T23-24-38Z\nCommit-ID: b52a3e523cc3c4debc0ea2f86386377df5355c81"
  latest_version_return = [body: '65a735f04bc1d35b4f86418226d5bbb4895cf7e1 minio.RELEASE.2019-09-05T23-24-38Z', status: 200]

  before :context do
    CheckMinioUpdate.class_variable_set(:@@autorun, false)
  end

  before(:each) do
    @api = stub_request(
      :get,
      'https://dl.min.io/server/minio/release/linux-amd64/minio.shasum'
    )

    @check = CheckMinioUpdate.new
    @check.config[:checkurl] = 'https://dl.min.io/server/minio/release'
    @check.config[:platform] = 'linux-amd64'

    allow(@check).to receive(:output)
  end

  it 'should be ok if versions are equal' do
    @api.to_return(latest_version_return)
    allow(status).to receive(:success?).and_return(true)
    allow(Open3).to receive(:capture3).with('minio version').and_return([local_version_return, nil, status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 0
    end
    expect(@check).to have_received(:output).with('No new minio version available')
    expect(@api).to have_been_requested
  end

  it 'should be critical if versions differ' do
    latest_version_return_diff = [body: '65a735f04bc1d35b4f86418226d5bbb4895cf7e1 minio.RELEASE.2019-09-11T19-53-16Z', status: 200]
    @api.to_return(latest_version_return_diff)
    allow(status).to receive(:success?).and_return(true)
    allow(Open3).to receive(:capture3).with('minio version').and_return([local_version_return, nil, status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 2
    end
    expect(@check).to have_received(:output).with('New minio version available RELEASE.2019-09-11T19-53-16Z')
    expect(@api).to have_been_requested
  end

  it 'should be unknown if minio not found' do
    @api.to_return(latest_version_return)
    allow(status).to receive(:success?).and_return(false)
    allow(Open3).to receive(:capture3).with('minio version').and_return([nil, 'Minio not found', status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 3
    end
    expect(@check).to have_received(:output).with('Unable to gather local minio version: Minio not found')
    expect(@api).to have_been_requested
  end

  it 'should be unknown if release url changes ' do
    not_found = [body: '404 Not Found', status: 404]
    @api.to_return(not_found)
    allow(status).to receive(:success?).and_return(false)
    allow(Open3).to receive(:capture3).with('minio version').and_return([local_version_return, nil, status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 3
    end
    expect(@check).to have_received(:output).with('Unable to gather latest minio version: 404 Not Found')
    expect(@api).to have_been_requested
  end
end
