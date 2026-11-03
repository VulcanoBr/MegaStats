
# frozen_string_literal: true

module MegaSena
  module Statistics
    class ParityAnalyzer
      NUMBERS_PER_DRAW = 6
      POSSIBLE_EVEN_COUNTS = (0..NUMBERS_PER_DRAW).freeze

      attr_reader :dataset

      def initialize(dataset:)
        @dataset = dataset
      end

      def call
        {
          total_draws: dataset.total_draws,
          analyzed_at: Time.current,
          metrics: metrics,
          data: distribution_data,
          rankings: rankings,
          most_frequent_distribution: most_frequent_distribution
        }
      end

      private

      def metrics
        {
          total_numbers: dataset.total_draws * NUMBERS_PER_DRAW,
          even_occurrences: even_occurrences,
          odd_occurrences: odd_occurrences,
          even_percentage: percentage_of_numbers(even_occurrences),
          odd_percentage: percentage_of_numbers(odd_occurrences),
          possible_distributions: POSSIBLE_EVEN_COUNTS.size
        }
      end

      def even_occurrences
        @even_occurrences ||= dataset.numbers.count(&:even?)
      end

      def odd_occurrences
        @odd_occurrences ||= dataset.numbers.count(&:odd?)
      end

      def distribution_counts
        @distribution_counts ||= begin
          counts = POSSIBLE_EVEN_COUNTS.to_h do |even_count|
            [even_count, 0]
          end

          dataset.each do |draw|
            even_count = draw.numbers.count(&:even?)
            counts[even_count] += 1
          end

          counts
        end
      end

      def distribution_data
        distribution_counts.map do |even_count, occurrences|
          odd_count = NUMBERS_PER_DRAW - even_count

          {
            even_count: even_count,
            odd_count: odd_count,
            label: distribution_label(even_count, odd_count),
            occurrences: occurrences,
            percentage: percentage_of_draws(occurrences)
          }
        end
      end

      def rankings
        ordered = distribution_data

        {
          most_frequent: ordered.sort_by do |item|
            [-item[:occurrences], item[:even_count]]
          end,

          least_frequent: ordered.sort_by do |item|
            [item[:occurrences], item[:even_count]]
          end
        }
      end

      def most_frequent_distribution
        return nil if dataset.empty?

        rankings[:most_frequent].first
      end

      def distribution_label(even_count, odd_count)
        "#{even_count}P - #{odd_count}I"
      end

      def percentage_of_draws(occurrences)
        return 0.0 if dataset.empty?

        occurrences.fdiv(dataset.total_draws) * 100
      end

      def percentage_of_numbers(occurrences)
        total_numbers = dataset.total_draws * NUMBERS_PER_DRAW

        return 0.0 if total_numbers.zero?

        occurrences.fdiv(total_numbers) * 100
      end
    end
  end
end
