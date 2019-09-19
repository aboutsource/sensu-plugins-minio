#!/usr/bin/env ruby
# frozen_string_literal: true

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
    uri = URI.parse("#{checkurl}/#{platform}/minio.shasum")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      latest_version = response.body.split.last.split('.', 2).last
    else
      unknown "Unable to gather latest minio version: #{response.body}"
    end

    stdout_str, error_str, status = Open3.capture3('minio version')
    if status.success?
      local_version = stdout_str.lines.at(1).split.last
    else
      unknown "Unable to gather local minio version: #{error_str}"
    end

    if latest_version == local_version
      ok 'No new minio version available'
    else
      critical "New minio version available #{latest_version}"
    end
  end
end
