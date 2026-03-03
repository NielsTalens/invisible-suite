# frozen_string_literal: true

module Timy
  class Processor
    def initialize(loader:, recognizer:, validator:, repository:, reporter:)
      @loader = loader
      @recognizer = recognizer
      @validator = validator
      @repository = repository
      @reporter = reporter
    end

    def run
      loaded = @loader.load
      entries = []
      @repository.clear_entries! if @repository.respond_to?(:clear_entries!)

      loaded[:valid].each do |message|
        raw = @recognizer.recognize(message)
        entry = @validator.validate(message, raw)
        @repository.append_entry(entry)
        entries << entry
      end

      @repository.append_log(
        {
          "processed" => loaded[:valid].length,
          "input_errors" => loaded[:errors].length
        }
      )

      @reporter.print(entries)
      { entries: entries, input_errors: loaded[:errors] }
    end
  end
end
