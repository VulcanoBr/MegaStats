
require "test_helper"

module MegaSena
  module Statistics
    class SequenceAnalyzerTest < ActiveSupport::TestCase
      test "identifica sequências consecutivas em um concurso" do
        create_draw(1, [5, 6, 7, 12, 15, 16])

        result = analyze
        draw = result[:data].first

        assert_equal [[5, 6, 7], [15, 16]], draw[:sequences]
        assert_equal 2, draw[:sequence_count]
      end

      test "identifica corretamente os pares consecutivos" do
        create_draw(1, [5, 6, 7, 12, 15, 16])

        result = analyze

        assert_equal 3, result[:data].first[:consecutive_pairs]
        assert_equal 3, result[:metrics][:total_consecutive_pairs]
      end

      test "identifica um concurso sem dezenas consecutivas" do
        create_draw(1, [1, 3, 5, 7, 9, 11])

        result = analyze
        draw = result[:data].first

        assert_empty draw[:sequences]
        assert_equal 0, draw[:sequence_count]
        assert_equal 0, draw[:consecutive_pairs]
      end

      test "identifica uma sequência única de seis dezenas" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze
        draw = result[:data].first

        assert_equal [[1, 2, 3, 4, 5, 6]], draw[:sequences]
        assert_equal 1, draw[:sequence_count]
        assert_equal 5, draw[:consecutive_pairs]
      end

      test "calcula os intervalos entre dezenas adjacentes" do
        create_draw(1, [5, 6, 7, 12, 15, 16])

        result = analyze

        assert_equal [1, 1, 5, 3, 1],
                     result[:data].first[:intervals]
      end

      test "calcula a quantidade total de intervalos" do
        create_draw(1, [5, 6, 7, 12, 15, 16])
        create_draw(2, [1, 3, 5, 7, 9, 11])

        result = analyze

        assert_equal 10, result[:metrics][:total_intervals]
      end

      test "calcula estatísticas dos intervalos" do
        create_draw(1, [5, 6, 7, 12, 15, 16])

        result = analyze
        metrics = result[:metrics]

        assert_equal 1, metrics[:minimum_interval]
        assert_equal 5, metrics[:maximum_interval]
        assert_in_delta 2.2, metrics[:average_interval], 0.001
        assert_equal 1.0, metrics[:median_interval]
      end

      test "contabiliza concursos com e sem sequências" do
        create_draw(1, [5, 6, 7, 12, 15, 16])
        create_draw(2, [1, 3, 5, 7, 9, 11])
        create_draw(3, [1, 2, 3, 4, 5, 6])

        result = analyze
        metrics = result[:metrics]

        assert_equal 3, metrics[:total_draws]
        assert_equal 2, metrics[:draws_with_sequences]
        assert_equal 1, metrics[:draws_without_sequences]

        assert_in_delta 66.6667,
                        metrics[:draws_with_sequences_percentage],
                        0.001

        assert_in_delta 33.3333,
                        metrics[:draws_without_sequences_percentage],
                        0.001
      end

      test "calcula a distribuição dos tamanhos das sequências" do
        create_draw(1, [5, 6, 7, 12, 15, 16])
        create_draw(2, [1, 2, 3, 4, 5, 6])

        result = analyze

        distribution = result[:sequence_size_distribution]

        assert_equal 5, distribution.size
        assert_equal 1, sequence_size_for(result, 2)[:occurrences]
        assert_equal 1, sequence_size_for(result, 3)[:occurrences]
        assert_equal 1, sequence_size_for(result, 6)[:occurrences]
        assert_equal 0, sequence_size_for(result, 4)[:occurrences]
      end

      test "os percentuais dos tamanhos das sequências somam 100%" do
        create_draw(1, [5, 6, 7, 12, 15, 16])
        create_draw(2, [1, 2, 3, 4, 5, 6])

        result = analyze

        total = result[:sequence_size_distribution].sum do |item|
          item[:percentage]
        end

        assert_in_delta 100.0, total, 0.001
      end

      test "calcula a distribuição dos intervalos" do
        create_draw(1, [5, 6, 7, 12, 15, 16])

        result = analyze

        assert_equal 55, result[:interval_distribution].size
        assert_equal 3, interval_for(result, 1)[:occurrences]
        assert_equal 1, interval_for(result, 3)[:occurrences]
        assert_equal 1, interval_for(result, 5)[:occurrences]
        assert_equal 0, interval_for(result, 2)[:occurrences]
      end

      test "os percentuais dos intervalos somam 100%" do
        create_draw(1, [5, 6, 7, 12, 15, 16])
        create_draw(2, [1, 3, 5, 7, 9, 11])

        result = analyze

        total = result[:interval_distribution].sum do |item|
          item[:percentage]
        end

        assert_in_delta 100.0, total, 0.001
      end

      test "identifica os concursos com maior quantidade de sequências" do
        create_draw(1, [5, 6, 7, 12, 15, 16])
        create_draw(2, [1, 2, 3, 4, 5, 6])
        create_draw(3, [1, 3, 5, 7, 9, 11])

        result = analyze

        ranking = result[:rankings][:contests_with_most_sequences]

        assert_equal 1, ranking.first[:contest_number]
        assert_equal 2, ranking.first[:sequence_count]
      end

      test "trata corretamente um dataset vazio" do
        dataset = Dataset.new(relation: Draw.none)

        result = SequenceAnalyzer.new(dataset: dataset).call
        metrics = result[:metrics]

        assert_equal 0, result[:total_draws]
        assert_equal 0, metrics[:draws_with_sequences]
        assert_equal 0, metrics[:draws_without_sequences]
        assert_equal 0, metrics[:total_sequences]
        assert_equal 0, metrics[:total_consecutive_pairs]
        assert_equal 0, metrics[:total_intervals]

        assert_equal 0.0, metrics[:average_interval]
        assert_nil metrics[:median_interval]
        assert_nil metrics[:minimum_interval]
        assert_nil metrics[:maximum_interval]

        assert_empty result[:data]
        assert_empty result[:rankings][:contests_with_most_sequences]

        assert result[:interval_distribution].all? do |item|
          item[:occurrences].zero? && item[:percentage].zero?
        end

        assert result[:sequence_size_distribution].all? do |item|
          item[:occurrences].zero? && item[:percentage].zero?
        end
      end

      private

      def analyze
        dataset = Dataset.new

        SequenceAnalyzer.new(dataset: dataset).call
      end

      def sequence_size_for(result, size)
        result[:sequence_size_distribution].find do |item|
          item[:size] == size
        end
      end

      def interval_for(result, interval)
        result[:interval_distribution].find do |item|
          item[:interval] == interval
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
