
require "test_helper"

module MegaSena
  module Statistics
    class SumAnalyzerTest < ActiveSupport::TestCase
      test "calcula a soma das seis dezenas de cada concurso" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])

        result = analyze

        assert_equal [21, 42],
                     result[:data].map { |item| item[:sum] }
      end

      test "calcula mínimo, máximo e amplitude" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze
        metrics = result[:metrics]

        assert_equal 21, metrics[:minimum]
        assert_equal 210, metrics[:maximum]
        assert_equal 189, metrics[:amplitude]
      end

      test "calcula a média aritmética" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        assert_in_delta 91.0,
                        result[:metrics][:mean],
                        0.001
      end

      test "calcula a mediana com quantidade ímpar de concursos" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        assert_equal 42.0, result[:metrics][:median]
      end

      test "calcula a mediana com quantidade par de concursos" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])

        result = analyze

        assert_equal 31.5, result[:metrics][:median]
      end

      test "calcula a variância e o desvio padrão populacionais" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        assert_in_delta 7_154.0,
                        result[:metrics][:variance],
                        0.001

        assert_in_delta Math.sqrt(7_154.0),
                        result[:metrics][:standard_deviation],
                        0.001
      end

      test "gera as treze faixas de soma" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal 13, result[:distribution].size

        assert_equal 21, result[:distribution].first[:minimum]
        assert_equal 45, result[:distribution].first[:maximum]

        assert_equal 321, result[:distribution].last[:minimum]
        assert_equal 345, result[:distribution].last[:maximum]
      end

      test "classifica corretamente as somas nas faixas" do
        create_draw(1, [1, 2, 3, 4, 5, 6])       # 21
        create_draw(2, [2, 4, 6, 8, 10, 12])    # 42
        create_draw(3, [10, 20, 30, 40, 50, 60]) # 210

        result = analyze

        first_range = range_for(result, 21)
        second_range = range_for(result, 46)
        eighth_range = range_for(result, 196)

        assert_equal 2, first_range[:occurrences]
        assert_equal 0, second_range[:occurrences]
        assert_equal 1, eighth_range[:occurrences]
      end

      test "calcula os percentuais das faixas" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        assert_in_delta 66.6667,
                        range_for(result, 21)[:percentage],
                        0.001

        assert_in_delta 33.3333,
                        range_for(result, 196)[:percentage],
                        0.001
      end

      test "a soma das ocorrências das faixas corresponde aos concursos" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        total = result[:distribution].sum do |item|
          item[:occurrences]
        end

        assert_equal 3, total
      end

      test "os percentuais das faixas somam 100%" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        total = result[:distribution].sum do |item|
          item[:percentage]
        end

        assert_in_delta 100.0, total, 0.001
      end

      test "identifica a faixa mais frequente" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [2, 4, 6, 8, 10, 12])
        create_draw(3, [10, 20, 30, 40, 50, 60])

        result = analyze

        assert_equal 21,
                     result[:most_frequent_range][:minimum]

        assert_equal 2,
                     result[:most_frequent_range][:occurrences]
      end

      test "trata corretamente um dataset vazio" do
        dataset = Dataset.new(relation: Draw.none)

        result = SumAnalyzer.new(dataset: dataset).call

        assert_equal 0, result[:total_draws]
        assert_nil result[:metrics][:minimum]
        assert_nil result[:metrics][:maximum]
        assert_nil result[:metrics][:mean]
        assert_nil result[:metrics][:median]
        assert_nil result[:metrics][:standard_deviation]
        assert_nil result[:metrics][:variance]
        assert_nil result[:metrics][:amplitude]

        assert_empty result[:data]
        assert_equal 13, result[:distribution].size
        assert_nil result[:most_frequent_range]

        assert(
          result[:distribution].all? do |item|
            item[:occurrences].zero? &&
              item[:percentage].zero?
          end
        )
      end

      test "calcula desvio padrão zero quando existe apenas um concurso" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal 0.0,
                     result[:metrics][:standard_deviation]

        assert_equal 0.0,
                     result[:metrics][:variance]
      end

      private

      def analyze
        dataset = Dataset.new

        SumAnalyzer.new(dataset: dataset).call
      end

      def range_for(result, minimum)
        result[:distribution].find do |item|
          item[:minimum] == minimum
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
