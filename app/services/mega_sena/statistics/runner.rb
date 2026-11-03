
# frozen_string_literal: true

module MegaSena
  module Statistics
    class Runner
      ANALYZERS = {
        frequency: FrequencyAnalyzer,
        parity: ParityAnalyzer,
        sum: SumAnalyzer,
        sequence: SequenceAnalyzer,
        delay: DelayAnalyzer,
        combination: CombinationAnalyzer
      }.freeze

      DEFAULT_ANALYZERS = ANALYZERS.keys.freeze

      attr_reader :dataset, :analyzer_names

      def initialize(
        dataset: nil,
        relation: Draw.all,
        analyzer_names: DEFAULT_ANALYZERS
      )
        @dataset = dataset || Dataset.new(relation: relation)
        @analyzer_names = normalize_analyzer_names(analyzer_names)

        validate_analyzer_names!
      end

      def call
        {
          generated_at: Time.current,
          dataset: dataset_metadata,
          analyses: execute_analyses
        }
      end

      private

      def normalize_analyzer_names(names)
        Array(names).map(&:to_sym).freeze
      end

      def validate_analyzer_names!
        unknown_names = analyzer_names - ANALYZERS.keys

        return if unknown_names.empty?

        raise ArgumentError,
              "Analisadores desconhecidos: #{unknown_names.join(', ')}"
      end

      def dataset_metadata
        {
          total_draws: dataset.total_draws,
          first_contest_number: dataset.first_contest_number,
          last_contest_number: dataset.last_contest_number
        }
      end

      def execute_analyses
        analyzer_names.each_with_object({}) do |name, results|
          analyzer_class = ANALYZERS.fetch(name)

          results[name] = analyzer_class.new(
            dataset: dataset
          ).call
        end
      end
    end
  end
end
