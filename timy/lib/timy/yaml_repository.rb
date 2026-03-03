# frozen_string_literal: true

require "yaml"
require "fileutils"

module Timy
  class YamlRepository
    def initialize(data_dir: "data")
      @data_dir = data_dir
      FileUtils.mkdir_p(@data_dir)
    end

    def append_entry(entry)
      append_to("timesheet_entries.yml", entry)
    end

    def append_log(log)
      append_to("processing_log.yml", log)
    end

    def clear_entries!
      path = File.join(@data_dir, "timesheet_entries.yml")
      File.write(path, YAML.dump([]))
    end

    private

    def append_to(file_name, item)
      path = File.join(@data_dir, file_name)
      current = File.exist?(path) ? YAML.load_file(path) : []
      current = [] unless current.is_a?(Array)
      current << item
      File.write(path, YAML.dump(current))
    end
  end
end
