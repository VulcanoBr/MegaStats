
require "test_helper"

module MegaSena
  module Statistics
    class ParityAnalyzerTest < ActiveSupport::TestCase
      test "calcula a quantidade total de dezenas pares e ímpares" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [7, 8, 9, 10, 11, 12])

        result = analyze

        assert_equal 12, result[:metrics][:total_numbers]
        assert_equal 6, result[:metrics][:even_occurrences]
        assert_equal 6, result[:metrics][:odd_occurrences]
      end

      test "calcula os percentuais gerais de pares e ímpares" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_in_delta 50.0,
                        result[:metrics][:even_percentage],
                        0.001

        assert_in_delta 50.0,
                        result[:metrics][:odd_percentage],
                        0.001
      end

      test "identifica corretamente as sete distribuições possíveis" do
        create_draw(1, [2, 4, 6, 8, 10, 12])
        create_draw(2, [1, 3, 5, 7, 9, 11])

        result = analyze

        assert_equal 7, result[:data].size

        assert_equal (0..6).to_a,
                     result[:data].map { |item| item[:even_count] }

        assert_equal 7,
                     result[:metrics][:possible_distributions]
      end

      test "classifica corretamente a distribuição de cada concurso" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [1, 3, 5, 7, 9, 11])

        result = analyze

        assert_equal 1, distribution_for(result, 3)[:occurrences]
        assert_equal 1, distribution_for(result, 6)[:occurrences]
        assert_equal 1, distribution_for(result, 0)[:occurrences]
      end

      test "calcula o percentual de cada distribuição" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])

        result = analyze

        assert_in_delta 50.0,
                        distribution_for(result, 3)[:percentage],
                        0.001

        assert_in_delta 50.0,
                        distribution_for(result, 6)[:percentage],
                        0.001

        assert_in_delta 0.0,
                        distribution_for(result, 0)[:percentage],
                        0.001
      end

      test "gera corretamente os rótulos das distribuições" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal "3P - 3I",
                     distribution_for(result, 3)[:label]

        assert_equal "0P - 6I",
                     distribution_for(result, 0)[:label]

        assert_equal "6P - 0I",
                     distribution_for(result, 6)[:label]
      end

      test "ordena as distribuições mais frequentes" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [1, 2, 3, 4, 5, 6])

        result = analyze

        ranking = result[:rankings][:most_frequent]

        assert_equal 3,
                     ranking.first[:even_count]

        assert_equal 2,
                     ranking.first[:occurrences]
      end

      test "ordena as distribuições menos frequentes" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 4, 5, 6])

        result = analyze

        ranking = result[:rankings][:least_frequent]

        assert_equal 0, ranking.first[:occurrences]
        assert_equal 0, ranking.first[:even_count]
      end

      test "identifica a distribuição mais frequente" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 4, 5, 6])
        create_draw(3, [2, 4, 6, 8, 10, 12])

        result = analyze

        assert_equal 3,
                     result[:most_frequent_distribution][:even_count]

        assert_equal 2,
                     result[:most_frequent_distribution][:occurrences]
      end

      test "os percentuais das distribuições somam 100%" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [1, 3, 5, 7, 9, 11])

        result = analyze

        total = result[:data].sum { |item| item[:percentage] }

        assert_in_delta 100.0, total, 0.001
      end

      test "trata um dataset vazio corretamente" do
        dataset = Dataset.new(relation: Draw.none)

        result = ParityAnalyzer.new(dataset: dataset).call

        assert_equal 0, result[:total_draws]
        assert_equal 0, result[:metrics][:total_numbers]
        assert_equal 0, result[:metrics][:even_occurrences]
        assert_equal 0, result[:metrics][:odd_occurrences]

        assert_equal 7, result[:data].size

        assert(
          result[:data].all? do |item|
            item[:occurrences].zero? &&
              item[:percentage].zero?
          end
        )

        assert_nil result[:most_frequent_distribution]
      end

      private

      def analyze
        dataset = Dataset.new

        ParityAnalyzer.new(dataset: dataset).call
      end

      def distribution_for(result, even_count)
        result[:data].find do |item|
          item[:even_count] == even_count
        end
      end

      def create_draw(contest_number, numbers)
        Draw.create!(
          contest_number: contest_number,
          draw_date: Date.new(2026, 1, contest_number),
          number_1: numbers[0],
          number_2: numbers[1],
          number_3: numbers[2],
          number_4: numbers[3],
          number_5: numbers[4],
          number_6: numbers[5]
        )
      end
    end
  end
end
