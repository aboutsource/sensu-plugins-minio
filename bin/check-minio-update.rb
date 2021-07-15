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
        latest_version = get_latest_version(checkurl, platform)
        local_version = get_local_version

        if local_version == latest_version
          ok 'No new minio version available'
        else
          critical "New minio version available #{latest_version}"
        end
      end
    rescue IOError => e
      unknown "#{e.message}"
    rescue Timeout::Error
      unknown 'Connection timed out'
    end
  end

  def get_latest_version(checkurl, platform)
    uri = URI.parse("#{checkurl}/#{platform}/minio.shasum")
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise IOError, "Unable to gather latest minio version: #{response.body}"
    end

    return response.body.split.last.split('.', 2).last
  end

  def get_local_version
    stdout, stderr, status = Open3.capture3([{'PATH' => ENV['PATH']}, 'minio --version', :unsetenv_others => true])

    raise IOError, "Unable to gather local minio version: #{stderr}" unless status.success?

    return stdout.split.last
  end
end
