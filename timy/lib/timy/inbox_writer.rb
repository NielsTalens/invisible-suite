# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

module Timy
  class InboxWriter
    def initialize(inbox_dir: "inbox")
      @inbox_dir = inbox_dir
      FileUtils.mkdir_p(@inbox_dir)
    end

    def write(payload)
      timestamp = Time.parse(payload.fetch("timestamp"))
      date_part = timestamp.utc.strftime("%Y-%m-%d")
      channel = payload.fetch("channel").to_s.strip.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      seq = next_sequence(channel, date_part)
      file_name = format("%s-%s-%03d.json", channel, date_part, seq)
      path = File.join(@inbox_dir, file_name)

      File.write(path, JSON.pretty_generate(payload))
      path
    end

    private

    def next_sequence(channel, date_part)
      pattern = File.join(@inbox_dir, "#{channel}-#{date_part}-*.json")
      existing = Dir.glob(pattern).map do |path|
        match = File.basename(path).match(/-(\d{3})\.json\z/)
        match ? match[1].to_i : 0
      end
      existing.empty? ? 1 : existing.max + 1
    end
  end
end
