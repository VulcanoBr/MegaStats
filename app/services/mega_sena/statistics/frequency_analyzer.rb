
# frozen_string_literal: true

module MegaSena
  module Statistics
    class FrequencyAnalyzer
      TOTAL_NUMBERS = 60
      NUMBERS_PER_DRAW = 6
      EXPECTED_PERCENTAGE = 10.0

      attr_reader :dataset

      def initialize(dataset:)
        @dataset = dataset
      end

      def call
        {
          total_draws: dataset.total_draws,
          analyzed_at: Time.current,
          metrics: metrics,
          data: frequency_data,
          rankings: rankings
        }
      end

      private

      def metrics
        {
          total_numbers: TOTAL_NUMBERS,
          numbers_per_draw: NUMBERS_PER_DRAW,
          total_occurrences: dataset.total_draws * NUMBERS_PER_DRAW,
          expected_percentage: EXPECTED_PERCENTAGE,
          expected_occurrences: expected_occurrences
        }
      end

      def expected_occurrences
        dataset.total_draws * NUMBERS_PER_DRAW.to_f / TOTAL_NUMBERS
      end

      def occurrence_counts
        @occurrence_counts ||= begin
          counts = Hash.new(0)

          (1..TOTAL_NUMBERS).each do |number|
            counts[number] = 0
          end

          dataset.each do |draw|
            draw.numbers.each do |number|
              counts[number] += 1
            end
          end

          counts
        end
      end

      def frequency_data
        occurrence_counts.map do |number, occurrences|
          {
            number: number,
            occurrences: occurrences,
            percentage: percentage(occurrences),
            difference_from_expected: occurrences - expected_occurrences
          }
        end
      end

      def rankings
        ordered = frequency_data

        {
          most_frequent: ordered.sort_by do |item|
            [-item[:occurrences], item[:number]]
          end,

          least_frequent: ordered.sort_by do |item|
            [item[:occurrences], item[:number]]
          end
        }
      end

      def percentage(occurrences)
        return 0.0 if dataset.empty?

        occurrences.fdiv(dataset.total_draws) * 100
      end
    end
  end
end
