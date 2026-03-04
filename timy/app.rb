# frozen_string_literal: true

require "sinatra/base"
require "json"
require "time"
require "stringio"
require_relative "lib/timy"

class TimyWeb < Sinatra::Base
  CHANNEL_IDENTITIES = {
    "mail" => "niels@example.com",
    "sms" => "+3165892356",
    "whatsapp" => "+3156455645"
  }.freeze

  configure do
    set :show_exceptions, false
    set :inbox_dir, "inbox"
    set :data_dir, "data"
    set :recognizer_factory, nil
    set :public_folder, File.expand_path("public", __dir__)
    set :views, File.expand_path("views", __dir__)
    set :static, true
  end

  get "/" do
    erb :index
  end

  get "/api/results" do
    content_type :json
    Timy::ResultsReader.new(data_dir: settings.data_dir).read.to_json
  end

  post "/api/submit-and-process" do
    content_type :json
    payload = parse_json_payload(request.body.read)
    validation_error, normalized = validate_and_normalize_payload(payload)
    return halt 422, { error: validation_error }.to_json if validation_error

    writer = Timy::InboxWriter.new(inbox_dir: settings.inbox_dir)
    created_source_files = []
    normalized.fetch("lines").each do |line|
      created_path = writer.write(
        "channel" => normalized.fetch("channel"),
        "sender" => normalized.fetch("sender"),
        "timestamp" => Time.now.utc.iso8601,
        "message" => line
      )
      created_source_files << File.basename(created_path)
    end

    recognizer = if settings.recognizer_factory.respond_to?(:call)
                   settings.recognizer_factory.call
                 else
                   Timy::OpenAiRecognizer.new
                 end

    processor = Timy::Processor.new(
      loader: Timy::InputLoader.new(settings.inbox_dir),
      recognizer: recognizer,
      validator: Timy::EntryValidator.new,
      repository: Timy::YamlRepository.new(data_dir: settings.data_dir),
      reporter: Timy::CliReporter.new(io: StringIO.new)
    )
    processor.run
    result = Timy::ResultsReader.new(data_dir: settings.data_dir).read
    result["created_source_files"] = created_source_files
    result.to_json
  rescue JSON::ParserError
    halt 422, { error: "Invalid JSON payload" }.to_json
  rescue StandardError => e
    halt 500, { error: e.message }.to_json
  end

  helpers do
    def parse_json_payload(body)
      JSON.parse(body)
    end

    def validate_and_normalize_payload(payload)
      return ["Payload must be a JSON object", nil] unless payload.is_a?(Hash)

      channel = payload["channel"].to_s.strip.downcase
      sender = CHANNEL_IDENTITIES[channel]
      return ["Invalid channel. Allowed: mail, sms, whatsapp", nil] if sender.nil?

      raw_lines = payload["lines"]
      return ["lines must be an array", nil] unless raw_lines.is_a?(Array)

      lines = raw_lines.map { |line| line.to_s.strip }.reject(&:empty?)
      return ["lines must contain at least one non-empty message", nil] if lines.empty?

      [nil, { "channel" => channel, "sender" => sender, "lines" => lines }]
    end
  end
end

if $PROGRAM_NAME == __FILE__
  TimyWeb.run!
end
