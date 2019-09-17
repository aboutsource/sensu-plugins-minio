#!/usr/bin/env ruby
#
# Check for minio updates
#
#
# OUTPUT:
#   plain text
#
#
# USAGE:
#   Check if minio updates are available for the local minio instance
#      ./check-minio-update.rb

require 'sensu-plugin/check/cli'
require 'sensu-plugin/utils'
require 'net/http'
require 'open3'

class CheckMinioUpdate < Sensu::Plugin::Check::CLI
  include Sensu::Plugin::Utils

  option :checkurl,
         description: 'Base URL to check for updates',
         short: '-u URL',
         long: '--url URL',
         default: 'https://dl.min.io/server/minio/release'

  option :platform,
         description: 'os platform',
         short: '-p PLATFORM',
         long: '--platform PLATFORM',
         default: 'linux-amd64'

  option :timeout,
         description: 'Request timeout in seconds',
         long: '--timeout TIMEOUT',
         default: 30

  def run
    checkurl = config[:checkurl]
    platform = config[:platform]
    timeout = config[:timeout].to_i

    begin
      Timeout.timeout(timeout) do
        check_update(checkurl, platform)
      end
    rescue Timeout::Error
      unknown 'Connection timed out'
    end
  end

  def check_update(checkurl, platform)
    uri = URI.parse(format('%<checkurl>s/%<platform>s/minio.shasum',
                           checkurl: checkurl, platform: platform))
    latest_version = Net::HTTP.get(uri).split.last

    stdout_str, error_str, status = Open3.capture3('sh -c "minio"')
    if status.success?
      minio_version = stdout_str.split.last
    else
      unknown format('Check failed: %<error>s', error: error_str)
    end

    if latest_version.split('.').last == minio_version.tr(':', '-')
      ok 'No new minio version available'
    else
      critical format('New minio version available %<version>s', version: latest_version)
    end
  end
end
