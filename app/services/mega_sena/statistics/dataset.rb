
# frozen_string_literal: true

module MegaSena
  module Statistics
    class Dataset
      NUMBER_ATTRIBUTES = %i[
        number_1
        number_2
        number_3
        number_4
        number_5
        number_6
      ].freeze

      DrawSnapshot = Struct.new(
        :contest_number,
        :draw_date,
        :numbers,
        keyword_init: true
      )

      attr_reader :draws

      def initialize(relation: Draw.all)
        @draws = load_draws(relation).freeze
      end

      def total_draws
        draws.size
      end

      def empty?
        draws.empty?
      end

      def each(&block)
        draws.each(&block)
      end

      def numbers
        draws.flat_map(&:numbers)
      end

      def first_contest_number
        draws.first&.contest_number
      end

      def last_contest_number
        draws.last&.contest_number
      end

      def contest_numbers
        draws.map(&:contest_number)
      end

      private

      def load_draws(relation)
        columns = [
          :contest_number,
          :draw_date,
          *NUMBER_ATTRIBUTES
        ]

        relation
          .reorder(:contest_number)
          .pluck(*columns)
          .map do |row|
            contest_number, draw_date, *numbers = row

            snapshot = DrawSnapshot.new(
              contest_number: contest_number,
              draw_date: draw_date,
              numbers: numbers.sort.freeze
            )

            snapshot.freeze
          end
      end
    end
  end
end
