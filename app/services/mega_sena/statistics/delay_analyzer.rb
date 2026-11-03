
# frozen_string_literal: true

module MegaSena
  module Statistics
    class DelayAnalyzer
      TOTAL_NUMBERS = 60

      attr_reader :dataset

      def initialize(dataset:)
        @dataset = dataset
      end

      def call
        {
          total_draws: dataset.total_draws,
          analyzed_at: Time.current,
          metrics: metrics,
          data: number_data,
          rankings: rankings
        }
      end

      private

      def number_data
        @number_data ||= (1..TOTAL_NUMBERS).map do |number|
          positions = appearance_positions.fetch(number)
          intervals = intervals_between_appearances(positions)
          historical_delays = intervals.map { |interval| interval - 1 }

          {
            number: number,
            occurrence_count: positions.size,
            first_appearance_contest: contest_at(positions.first),
            last_appearance_contest: contest_at(positions.last),
            current_delay: current_delay(positions),
            intervals_between_appearances: intervals,
            average_interval_between_appearances: average(intervals),
            historical_delays: historical_delays,
            maximum_historical_delay: historical_delays.max,
            average_historical_delay: average(historical_delays)
          }
        end
      end

      def appearance_positions
        @appearance_positions ||= begin
          positions = (1..TOTAL_NUMBERS).to_h do |number|
            [number, []]
          end

          dataset.draws.each_with_index do |draw, index|
            draw.numbers.each do |number|
              positions[number] << index
            end
          end

          positions
        end
      end

      def intervals_between_appearances(positions)
        positions.each_cons(2).map do |first_position, second_position|
          second_position - first_position
        end
      end

      def current_delay(positions)
        return nil if dataset.empty?
        return dataset.total_draws if positions.empty?

        (dataset.total_draws - 1) - positions.last
      end

      def contest_at(position)
        return nil if position.nil?

        dataset.draws[position].contest_number
      end

      
      def metrics
        {
          total_numbers: TOTAL_NUMBERS,
          total_occurrences: number_data.sum { |item| item[:occurrence_count] },
          total_historical_intervals: number_data.sum do |item|
            item[:intervals_between_appearances].size
          end,
          total_historical_delays: historical_delays.size,

          average_current_delay: average(current_delays),
          maximum_current_delay: current_delays.max,

          average_interval_between_appearances: average(
            number_data.flat_map { |item| item[:intervals_between_appearances] }
          ),

          average_historical_delay: average(historical_delays),
          maximum_historical_delay: historical_delays.max,

          numbers_never_drawn: number_data.count do |item|
            item[:occurrence_count].zero?
          end,
          numbers_drawn_once: number_data.count do |item|
            item[:occurrence_count] == 1
          end,
          numbers_drawn_more_than_once: number_data.count do |item|
            item[:occurrence_count] > 1
          end
        }
      end

      def historical_delays
        number_data.flat_map { |item| item[:historical_delays] }
      end

      def current_delays
        number_data.filter_map { |item| item[:current_delay] }
      end

      def rankings
        {
          most_delayed_current: number_data.sort_by do |item|
            [-item[:current_delay].to_i, item[:number]]
          end,

          least_delayed_current: number_data.sort_by do |item|
            [item[:current_delay].to_i, item[:number]]
          end,

          largest_historical_delay: number_data
            .select { |item| item[:maximum_historical_delay] }
            .sort_by do |item|
              [-item[:maximum_historical_delay], item[:number]]
            end,

          most_frequent: number_data.sort_by do |item|
            [-item[:occurrence_count], item[:number]]
          end
        }
      end

      def average(values)
        return nil if values.empty?

        values.sum.fdiv(values.size)
      end
    end
  end
end
