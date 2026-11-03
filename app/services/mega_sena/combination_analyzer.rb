
# frozen_string_literal: true

module MegaSena
  class CombinationAnalyzer
    attr_reader :numbers, :dataset

    def initialize(numbers:, dataset: nil)
      @numbers = Array(numbers).map { |number| Integer(number) }.sort
      @dataset = dataset || Statistics::Dataset.new

      validate_numbers!
    end

    def call
      matches = matching_draws

      {
        numbers: numbers,
        historical_occurrences: matches.size,
        contests: matches.map(&:contest_number),
        theoretical_probability: "1 em 50063860",
        number_statistics: number_statistics
      }
    end

    private

    def matching_draws
      dataset.draws.select do |draw|
        draw_numbers(draw) == numbers
      end
    end

    def number_statistics
      frequency_data = frequency_analysis
      delay_data = delay_analysis

      numbers.map do |number|
        frequency = frequency_data.fetch(number)
        delay = delay_data.fetch(number)

        {
          number: number,
          occurrence_count: frequency[:occurrences],
          current_delay: delay[:current_delay],
          last_appearance_contest: delay[:last_appearance_contest]
        }
      end
    end

    def frequency_analysis
      result = Statistics::FrequencyAnalyzer.new(
        dataset: dataset
      ).call

      result[:data].index_by { |item| item[:number] }
    end

    def delay_analysis
      result = Statistics::DelayAnalyzer.new(
        dataset: dataset
      ).call

      result[:data].index_by { |item| item[:number] }
    end

    def validate_numbers!
      unless numbers.size == 6 &&
             numbers.all? { |number| (1..60).cover?(number) } &&
             numbers.uniq.size == 6
        raise ArgumentError,
              "Informe exatamente seis números distintos entre 1 e 60."
      end
    end

    def draw_numbers(draw)
      draw.numbers.sort
    end
  end
end
