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

  RELEASE_PATTERN = /(?<release>RELEASE.\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}Z)/.freeze # rubocop:disable Layout/LineLength

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
    Timeout.timeout(config[:timeout].to_i) do
      if local_version == latest_version
        ok 'No new minio version available'
      else
        critical "New minio version available #{latest_version}"
      end
    end
  rescue IOError => e
    unknown e.message.to_s
  rescue Timeout::Error
    unknown 'Connection timed out'
  end

  private

  def latest_version
    @latest_version ||= begin
      uri = URI.parse("#{config[:checkurl]}/#{config[:platform]}/minio.sha256sum") # rubocop:disable Layout/LineLength
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise IOError, "Unable to gather latest minio version: #{response.body}"
      end

      extract_release(response.body)
    end
  end

  def local_version
    @local_version ||= begin
      stdout, stderr, status = Open3.capture3(
        { 'PATH' => ENV['PATH'] }, 'journalctl --boot --unit minio | grep "Version: RELEASE" | tail -n 1', unsetenv_others: true # rubocop:disable Layout/LineLength
      )

      unless status.success?
        raise IOError, "Unable to gather local minio version: #{stderr}"
      end

      extract_release(stdout)
    end
  end

  def extract_release(release_source_str)
    match_data = RELEASE_PATTERN.match(release_source_str)

    if match_data.nil?
      raise IOError, "Unable to extract release: #{release_source_str}"
    end

    match_data[:release]
  end
end
