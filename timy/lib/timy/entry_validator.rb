# frozen_string_literal: true

require "json"

module Timy
  class EntryValidator
    CONFIDENCE = %w[high medium low].freeze
    STATUS = %w[ok needs_clarification].freeze
    FALLBACK_QUESTION = "I could not fully parse this message. Could you clarify the project, date, and time spent?"
    DEFAULT_CATALOG_PATH = File.expand_path("../../data/projects_tasks.json", __dir__)

    def initialize(catalog: nil, catalog_path: DEFAULT_CATALOG_PATH)
      loaded_catalog = catalog || load_catalog(catalog_path)
      @projects = extract_projects(loaded_catalog)
      @task_aliases = build_task_aliases(loaded_catalog)
      @task_names = extract_task_names(loaded_catalog)
    end

    def validate(source, raw_entry)
      normalized = raw_entry.is_a?(Hash) ? raw_entry : {}
      entry = base_entry(source).merge(normalized)
      if !raw_entry.nil? && !raw_entry.is_a?(Hash)
        entry["_recognizer_error"] = "Recognizer returned #{raw_entry.class}, expected Hash"
      end

      if valid_entry?(entry)
        apply_catalog_rules(entry)
        if entry["status"] == "needs_clarification"
          entry["clarification_question"] = safe_question(entry["clarification_question"])
        else
          entry.delete("clarification_question")
        end
        return entry
      end

      fallback_entry(entry)
    end

    private

    def base_entry(source)
      {
        "source_file" => source["source_file"],
        "channel" => source["channel"],
        "sender" => source["sender"],
        "original_timestamp" => source["timestamp"]
      }
    end

    def valid_entry?(entry)
      required = %w[work_date project task_description duration_hours confidence status]
      return false unless required.all? { |k| entry.key?(k) }
      return false unless entry["duration_hours"].is_a?(Numeric)
      return false unless CONFIDENCE.include?(entry["confidence"])
      return false unless STATUS.include?(entry["status"])

      true
    end

    def fallback_entry(entry)
      result = {
        "source_file" => entry["source_file"],
        "channel" => entry["channel"],
        "sender" => entry["sender"],
        "original_timestamp" => entry["original_timestamp"],
        "work_date" => entry["work_date"],
        "project" => entry["project"] || "unknown",
        "task_description" => entry["task_description"] || "Unable to extract task details",
        "duration_hours" => entry["duration_hours"].is_a?(Numeric) ? entry["duration_hours"] : 0.0,
        "confidence" => "low",
        "status" => "needs_clarification",
        "clarification_question" => safe_question(entry["clarification_question"])
      }

      result["_recognizer_error"] = entry["_recognizer_error"] if entry.key?("_recognizer_error")
      result
    end

    def safe_question(value)
      return FALLBACK_QUESTION if value.nil? || value.strip.empty?

      value
    end

    def apply_catalog_rules(entry)
      return if @projects.empty? && @task_aliases.empty?

      normalized_project = normalize_project(entry["project"])
      normalized_task = normalize_task(entry["task_description"])

      entry["project"] = normalized_project if normalized_project
      entry["task_description"] = normalized_task if normalized_task
      return if normalized_project && normalized_task

      feedback = []
      unless normalized_project
        feedback << "Project '#{entry["project"]}' is not valid. Use one of: #{@projects.join(', ')}."
      end
      unless normalized_task
        feedback << "Task '#{entry["task_description"]}' is not valid. Use one of: #{@task_names.join(', ')}."
      end

      entry["status"] = "needs_clarification"
      entry["confidence"] = "low"
      entry["clarification_question"] = feedback.join(" ")
    end

    def normalize_project(value)
      resolve_candidate(value, @projects)
    end

    def normalize_task(value)
      raw = value.to_s
      normalized = normalize_key(raw)
      return nil if normalized.empty?

      direct = @task_aliases[normalized]
      return direct if direct

      contains_match = @task_aliases.find { |candidate_key, _canonical| normalized.include?(candidate_key) }
      return contains_match[1] if contains_match

      best_distance = nil
      best_task = nil
      ties = 0

      @task_aliases.each do |candidate_key, canonical|
        distance = damerau_levenshtein(normalized, candidate_key)
        next unless accepted_distance?(normalized.length, distance)

        if best_distance.nil? || distance < best_distance
          best_distance = distance
          best_task = canonical
          ties = 1
        elsif distance == best_distance
          ties += 1
        end
      end

      ties == 1 ? best_task : nil
    end

    def resolve_candidate(value, candidates)
      raw = value.to_s
      normalized = normalize_key(raw)
      return nil if normalized.empty?

      exact = candidates.find { |candidate| normalize_key(candidate) == normalized }
      return exact if exact

      contains = candidates.find do |candidate|
        candidate_key = normalize_key(candidate)
        !candidate_key.empty? && normalized.include?(candidate_key)
      end
      return contains if contains

      best_distance = nil
      best_candidate = nil
      ties = 0

      candidates.each do |candidate|
        distance = damerau_levenshtein(normalized, normalize_key(candidate))
        next unless accepted_distance?(normalized.length, distance)

        if best_distance.nil? || distance < best_distance
          best_distance = distance
          best_candidate = candidate
          ties = 1
        elsif distance == best_distance
          ties += 1
        end
      end

      ties == 1 ? best_candidate : nil
    end

    def accepted_distance?(input_length, distance)
      return distance <= 1 if input_length <= 4
      return distance <= 2 if input_length <= 8

      distance <= 3
    end

    def normalize_key(value)
      value.to_s.downcase.gsub(/\band\b/, "").gsub(/[^a-z0-9]/, "")
    end

    def damerau_levenshtein(a, b)
      m = a.length
      n = b.length
      return n if m.zero?
      return m if n.zero?

      d = Array.new(m + 1) { Array.new(n + 1, 0) }
      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }

      (1..m).each do |i|
        (1..n).each do |j|
          cost = a[i - 1] == b[j - 1] ? 0 : 1
          d[i][j] = [
            d[i - 1][j] + 1,
            d[i][j - 1] + 1,
            d[i - 1][j - 1] + cost
          ].min

          if i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]
            d[i][j] = [d[i][j], d[i - 2][j - 2] + cost].min
          end
        end
      end

      d[m][n]
    end

    def load_catalog(path)
      return {} unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue StandardError
      {}
    end

    def extract_projects(catalog)
      projects = catalog.fetch("projects", [])
      return [] unless projects.is_a?(Array)

      projects.map(&:to_s).reject(&:empty?)
    end

    def extract_task_names(catalog)
      tasks = catalog.fetch("tasks", {})
      if tasks.is_a?(Hash)
        tasks.keys.map(&:to_s).reject(&:empty?)
      elsif tasks.is_a?(Array)
        tasks.map(&:to_s).reject(&:empty?)
      else
        []
      end
    end

    def build_task_aliases(catalog)
      tasks = catalog.fetch("tasks", {})
      aliases = {}

      if tasks.is_a?(Hash)
        tasks.each do |canonical, alt_names|
          canonical_name = canonical.to_s.strip
          next if canonical_name.empty?

          names = [canonical_name]
          names.concat(Array(alt_names).map(&:to_s))
          names.each do |name|
            key = normalize_key(name)
            next if key.empty?

            aliases[key] = canonical_name
          end
        end
      elsif tasks.is_a?(Array)
        tasks.each do |name|
          canonical_name = name.to_s.strip
          key = normalize_key(canonical_name)
          next if canonical_name.empty? || key.empty?

          aliases[key] = canonical_name
        end
      end

      aliases
    end
  end
end
