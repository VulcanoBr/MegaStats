
# frozen_string_literal: true

module MegaSena
  module Statistics
    class SumAnalyzer
      MIN_POSSIBLE_SUM = 21
      MAX_POSSIBLE_SUM = 345
      RANGE_WIDTH = 25

      SUM_RANGES = (0...13).map do |index|
        minimum = MIN_POSSIBLE_SUM + (index * RANGE_WIDTH)
        maximum = [minimum + RANGE_WIDTH - 1, MAX_POSSIBLE_SUM].min

        {
          minimum: minimum,
          maximum: maximum
        }.freeze
      end.freeze

      attr_reader :dataset

      def initialize(dataset:)
        @dataset = dataset
      end

      def call
        {
          total_draws: dataset.total_draws,
          analyzed_at: Time.current,
          metrics: metrics,
          data: sum_data,
          distribution: distribution_data,
          rankings: rankings,
          most_frequent_range: most_frequent_range
        }
      end

      private

      def sums
        @sums ||= dataset.draws.map do |draw|
          draw.numbers.sum
        end
      end

      def metrics
        return empty_metrics if sums.empty?

        {
          minimum: sums.min,
          maximum: sums.max,
          mean: mean,
          median: median,
          standard_deviation: standard_deviation,
          variance: variance,
          amplitude: sums.max - sums.min
        }
      end

      def empty_metrics
        {
          minimum: nil,
          maximum: nil,
          mean: nil,
          median: nil,
          standard_deviation: nil,
          variance: nil,
          amplitude: nil
        }
      end

      def mean
        @mean ||= sums.sum.fdiv(sums.size)
      end

      def median
        @median ||= begin
          ordered = sums.sort
          middle = ordered.size / 2

          if ordered.size.odd?
            ordered[middle].to_f
          else
            (ordered[middle - 1] + ordered[middle]).fdiv(2)
          end
        end
      end

      def variance
        @variance ||= begin
          squared_differences = sums.sum do |value|
            (value - mean)**2
          end

          squared_differences.fdiv(sums.size)
        end
      end

      def standard_deviation
        Math.sqrt(variance)
      end

      def sum_data
        dataset.draws.map do |draw| 
          {
            contest_number: draw.contest_number,
            draw_date: draw.draw_date,
            sum: draw.numbers.sum
          }
        end
      end

      def distribution_counts
        @distribution_counts ||= begin
          counts = SUM_RANGES.to_h do |range|
            [range[:minimum], 0]
          end

          sums.each do |sum|
            range = SUM_RANGES.find do |item|
              sum.between?(item[:minimum], item[:maximum])
            end

            counts[range[:minimum]] += 1 if range
          end

          counts
        end
      end

      def distribution_data
        SUM_RANGES.map do |range|
          occurrences = distribution_counts.fetch(range[:minimum])

          {
            minimum: range[:minimum],
            maximum: range[:maximum],
            label: range_label(range),
            occurrences: occurrences,
            percentage: percentage(occurrences)
          }
        end
      end

      def rankings
        ordered = distribution_data

        {
          most_frequent: ordered.sort_by do |item|
            [-item[:occurrences], item[:minimum]]
          end,

          least_frequent: ordered.sort_by do |item|
            [item[:occurrences], item[:minimum]]
          end
        }
      end

      def most_frequent_range
        return nil if dataset.empty?

        rankings[:most_frequent].first
      end

      def range_label(range)
        "#{range[:minimum]}–#{range[:maximum]}"
      end

      def percentage(occurrences)
        return 0.0 if dataset.empty?

        occurrences.fdiv(dataset.total_draws) * 100
      end
    end
  end
end
