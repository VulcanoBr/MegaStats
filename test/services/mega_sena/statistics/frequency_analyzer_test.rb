
require "test_helper"

module MegaSena
  module Statistics
    class FrequencyAnalyzerTest < ActiveSupport::TestCase
      test "calcula a frequência absoluta das dezenas" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 7, 8, 9, 10])

        result = analyze

        assert_equal 2, frequency_for(result, 1)[:occurrences]
        assert_equal 2, frequency_for(result, 2)[:occurrences]
        assert_equal 1, frequency_for(result, 3)[:occurrences]
        assert_equal 0, frequency_for(result, 60)[:occurrences]
      end

      test "calcula a frequência relativa corretamente" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 7, 8, 9, 10])

        result = analyze

        assert_in_delta 100.0, frequency_for(result, 1)[:percentage]
        assert_in_delta 50.0, frequency_for(result, 3)[:percentage]
        assert_in_delta 0.0, frequency_for(result, 60)[:percentage]
      end

      test "retorna as sessenta dezenas" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal 60, result[:data].size
        assert_equal (1..60).to_a,
                     result[:data].map { |item| item[:number] }
      end

      test "calcula a quantidade total de ocorrências" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [7, 8, 9, 10, 11, 12])

        result = analyze

        assert_equal 12, result[:metrics][:total_occurrences]
      end

      test "calcula a frequência esperada" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [7, 8, 9, 10, 11, 12])

        result = analyze

        assert_equal 10.0,
                     result[:metrics][:expected_percentage]

        assert_in_delta 0.2,
                        result[:metrics][:expected_occurrences]
      end

      test "ordena o ranking das dezenas mais frequentes" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 7, 8, 9, 10])

        result = analyze

        ranking = result[:rankings][:most_frequent]

        assert_equal [1, 2], ranking.first(2).map { |item| item[:number] }
      end

      test "ordena o ranking das dezenas menos frequentes" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 7, 8, 9, 10])

        result = analyze

        ranking = result[:rankings][:least_frequent]

        assert_equal 0, ranking.first[:occurrences]
        assert_equal 11, ranking.first[:number]
      end

      test "trata um dataset vazio sem divisão por zero" do
        dataset = Dataset.new(relation: Draw.none)

        result = FrequencyAnalyzer.new(dataset: dataset).call

        assert_equal 0, result[:total_draws]
        assert_equal 60, result[:data].size
        assert result[:data].all? { |item| item[:percentage].zero? }
        assert_equal 0.0, result[:metrics][:expected_occurrences]
      end

      private

      def analyze
        dataset = Dataset.new

        FrequencyAnalyzer.new(dataset: dataset).call
      end

      def frequency_for(result, number)
        result[:data].find { |item| item[:number] == number }
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
