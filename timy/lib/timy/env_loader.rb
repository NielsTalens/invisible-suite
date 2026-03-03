# frozen_string_literal: true

module Timy
  module EnvLoader
    module_function

    def load(path = ".env")
      return unless File.exist?(path)

      File.readlines(path, chomp: true).each do |line|
        next if line.strip.empty? || line.strip.start_with?("#")

        key, value = line.split("=", 2)
        next if key.nil? || value.nil?

        ENV[key] = value unless ENV.key?(key)
      end
    end
  end
end
