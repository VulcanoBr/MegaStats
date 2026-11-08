
module MegaSena
  module Statistics
    class WinnerRangeAnalysis
      NUMBER_COLUMNS = (1..6).map { |number| :"number_#{number}" }.freeze

      def initialize(minimum_winners:, maximum_winners:)
        @minimum_winners = parse_integer(minimum_winners)
        @maximum_winners = parse_integer(maximum_winners)

        validate_range!
      end

      def call
        draws = Draw
          .where(winners_sena: @minimum_winners..@maximum_winners)
          .pluck(*NUMBER_COLUMNS)

        total_draws = draws.size

        frequencies = Hash.new(0)

        draws.each do |draw_numbers|
          draw_numbers.each do |number|
            frequencies[number] += 1
          end
        end

        number_results = (1..60).map do |number|
          appearances = frequencies[number]
          non_appearances = total_draws - appearances

          {
            number: number,
            appearances: appearances,
            non_appearances: non_appearances,
            appearance_percentage: percentage(appearances, total_draws),
            non_appearance_percentage: percentage(non_appearances, total_draws)
          }
        end

        {
          minimum_winners: @minimum_winners,
          maximum_winners: @maximum_winners,
          total_draws: total_draws,
          numbers: number_results
        }
      end

      private

      def parse_integer(value)
        Integer(value.to_s, 10)
      rescue ArgumentError, TypeError
        raise ArgumentError, "Informe valores inteiros para a faixa de ganhadores."
      end

      def validate_range!
        if @minimum_winners.negative? || @maximum_winners.negative?
          raise ArgumentError, "A quantidade de ganhadores não pode ser negativa."
        end

        if @minimum_winners > @maximum_winners
          raise ArgumentError, "O mínimo não pode ser maior que o máximo."
        end
      end

      def percentage(quantity, total)
        return 0.0 if total.zero?

        (quantity.to_f / total * 100).round(2)
      end
    end
  end
end
