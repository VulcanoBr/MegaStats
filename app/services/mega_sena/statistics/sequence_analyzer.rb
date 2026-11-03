
# frozen_string_literal: true

module MegaSena
  module Statistics
    class SequenceAnalyzer
      NUMBERS_PER_DRAW = 6
      MIN_SEQUENCE_SIZE = 2
      MAX_SEQUENCE_SIZE = 6

      MIN_INTERVAL = 1
      MAX_INTERVAL = 55

      attr_reader :dataset

      def initialize(dataset:)
        @dataset = dataset
      end

      def call
        {
          total_draws: dataset.total_draws,
          analyzed_at: Time.current,
          metrics: metrics,
          data: draw_data,
          sequence_size_distribution: sequence_size_distribution,
          interval_distribution: interval_distribution,
          rankings: rankings
        }
      end

      private

      def draw_data
        @draw_data ||= dataset.draws.map do |draw|
          sequences = consecutive_sequences(draw.numbers)
          intervals = calculate_intervals(draw.numbers)

          {
            contest_number: draw.contest_number,
            draw_date: draw.draw_date,
            numbers: draw.numbers,
            sequences: sequences,
            sequence_count: sequences.size,
            consecutive_pairs: intervals.count(1),
            intervals: intervals
          }
        end
      end

      def metrics
        {
          total_draws: dataset.total_draws,
          draws_with_sequences: draws_with_sequences,
          draws_without_sequences: draws_without_sequences,
          draws_with_sequences_percentage: percentage(draws_with_sequences),
          draws_without_sequences_percentage: percentage(draws_without_sequences),
          total_sequences: total_sequences,
          total_consecutive_pairs: total_consecutive_pairs,
          average_sequences_per_draw: average_sequences_per_draw,
          average_consecutive_pairs_per_draw: average_consecutive_pairs_per_draw,
          total_intervals: intervals.size,
          average_interval: average(intervals),
          median_interval: median(intervals),
          minimum_interval: intervals.min,
          maximum_interval: intervals.max
        }
      end

      def consecutive_sequences(numbers)
        groups = []
        current_group = []

        numbers.each do |number|
          if current_group.empty? || number == current_group.last + 1
            current_group << number
          else
            groups << current_group if current_group.size >= MIN_SEQUENCE_SIZE
            current_group = [number]
          end
        end

        groups << current_group if current_group.size >= MIN_SEQUENCE_SIZE

        groups
      end

      def calculate_intervals(numbers)
        numbers.each_cons(2).map do |first, second|
          second - first
        end
      end

      def draws_with_sequences
        draw_data.count { |item| item[:sequence_count].positive? }
      end

      def draws_without_sequences
        dataset.total_draws - draws_with_sequences
      end

      def total_sequences
        draw_data.sum { |item| item[:sequence_count] }
      end

      def total_consecutive_pairs
        draw_data.sum { |item| item[:consecutive_pairs] }
      end

      def average_sequences_per_draw
        return 0.0 if dataset.empty?

        total_sequences.fdiv(dataset.total_draws)
      end

      def average_consecutive_pairs_per_draw
        return 0.0 if dataset.empty?

        total_consecutive_pairs.fdiv(dataset.total_draws)
      end

      def intervals
        @intervals ||= draw_data.flat_map { |item| item[:intervals] }
      end

      def sequence_size_distribution
        counts = (MIN_SEQUENCE_SIZE..MAX_SEQUENCE_SIZE).to_h do |size|
          [size, 0]
        end

        draw_data.each do |item|
          item[:sequences].each do |sequence|
            counts[sequence.size] += 1
          end
        end

        counts.map do |size, occurrences|
          {
            size: size,
            label: "#{size} dezenas",
            occurrences: occurrences,
            percentage: percentage_of_sequences(occurrences)
          }
        end
      end

      def interval_distribution
        counts = (MIN_INTERVAL..MAX_INTERVAL).to_h do |interval|
          [interval, 0]
        end

        intervals.each do |interval|
          counts[interval] += 1
        end

        counts.map do |interval, occurrences|
          {
            interval: interval,
            occurrences: occurrences,
            percentage: percentage_of_intervals(occurrences)
          }
        end
      end

      def rankings
        {
          most_frequent_sequence_sizes: sequence_size_distribution.sort_by do |item|
            [-item[:occurrences], item[:size]]
          end,

          most_frequent_intervals: interval_distribution.sort_by do |item|
            [-item[:occurrences], item[:interval]]
          end,

          contests_with_most_sequences: draw_data.sort_by do |item|
            [-item[:sequence_count], item[:contest_number]]
          end
        }
      end

      def average(values)
        return 0.0 if values.empty?

        values.sum.fdiv(values.size)
      end

      def median(values)
        return nil if values.empty?

        ordered = values.sort
        middle = ordered.size / 2

        if ordered.size.odd?
          ordered[middle].to_f
        else
          (ordered[middle - 1] + ordered[middle]).fdiv(2)
        end
      end

      def percentage(occurrences)
        return 0.0 if dataset.empty?

        occurrences.fdiv(dataset.total_draws) * 100
      end

      def percentage_of_sequences(occurrences)
        total = draw_data.sum { |item| item[:sequence_count] }

        return 0.0 if total.zero?

        occurrences.fdiv(total) * 100
      end

      def percentage_of_intervals(occurrences)
        return 0.0 if intervals.empty?

        occurrences.fdiv(intervals.size) * 100
      end
    end
  end
end
