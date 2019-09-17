require 'json'
require 'webmock/rspec'

require_relative '../bin/check-minio-update.rb'

describe CheckMinioUpdate do
  let(:status) { double }

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

  it 'should bo ok if versions are equal' do
    @api.to_return(body: '65a735f04bc1d35b4f86418226d5bbb4895cf7e1 minio.RELEASE.2019-09-11T19-53-16Z', status: 200)
    allow(status).to receive(:success?).and_return(true)
    allow(Open3).to receive(:capture3).with('sh -c "minio"').and_return(['2019-09-11T19-53-16Z', nil, status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 0
    end
    expect(@check).to have_received(:output).with('No new minio version available')
    expect(@api).to have_been_requested
  end

  it 'should be critical if versions differ' do
    @api.to_return(body: '65a735f04bc1d35b4f86418226d5bbb4895cf7e1 minio.RELEASE.2019-09-11T19-53-16Z', status: 200)
    allow(status).to receive(:success?).and_return(true)
    allow(Open3).to receive(:capture3).with('sh -c "minio"').and_return(['2019-09-05T19-53-16Z', nil, status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 2
    end
    expect(@check).to have_received(:output).with('New minio version available minio.RELEASE.2019-09-11T19-53-16Z')
    expect(@api).to have_been_requested
  end

  it 'should be unknown if minio not found' do
    @api.to_return(body: '65a735f04bc1d35b4f86418226d5bbb4895cf7e1 minio.RELEASE.2019-09-11T19-53-16Z', status: 200)
    allow(status).to receive(:success?).and_return(false)
    allow(Open3).to receive(:capture3).with('sh -c "minio"').and_return([nil, 'Minio not found', status])

    expect { @check.run }.to raise_error do |error|
      expect(error).to be_a SystemExit
      expect(error.status).to eq 3
    end
    expect(@check).to have_received(:output).with('Check failed: Minio not found')
    expect(@api).to have_been_requested
  end
end
