
# frozen_string_literal: true

require "test_helper"

module MegaSena
  module Statistics
    class CombinationAnalyzerTest < ActiveSupport::TestCase
      setup do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 7, 8, 9])
        create_draw(3, [1, 4, 7, 10, 11, 12])

        @dataset = Dataset.new
        @result = CombinationAnalyzer.new(dataset: @dataset).call
      end

      test "retorna a estrutura principal da análise" do
        assert_equal 3, @result[:total_draws]

        assert @result.key?(:metrics)
        assert @result.key?(:pairs)
        assert @result.key?(:triples)
        assert @result.key?(:complete_combinations)
        assert @result.key?(:consecutive_draws)
        assert @result.key?(:rankings)
      end

      test "calcula corretamente as ocorrências de pares" do
        pairs = @result[:pairs]

        assert_equal 1_770, pairs[:total_possible]
        assert_equal 45, pairs[:total_occurrences]
        assert_equal 40, pairs[:distinct_observed]

        pair = pairs[:data].find do |item|
          item[:numbers] == [1, 2]
        end

        assert_equal 2, pair[:occurrence_count]
        assert_in_delta 66.6667, pair[:percentage], 0.001
      end

      test "identifica pares recorrentes" do
        recurrent = @result[:pairs][:recurrent]

        assert recurrent.any? do |item|
          item[:numbers] == [1, 2] &&
            item[:occurrence_count] == 2
        end

        assert_equal 5, recurrent.size
      end

      test "calcula corretamente as ocorrências de trincas" do
        triples = @result[:triples]

        assert_equal 34_220, triples[:total_possible]
        assert_equal 60, triples[:total_occurrences]
        assert_equal 59, triples[:distinct_observed]

        triple = triples[:data].find do |item|
          item[:numbers] == [1, 2, 3]
        end

        assert_equal 2, triple[:occurrence_count]
        assert_in_delta 66.6667, triple[:percentage], 0.001
      end

      test "identifica trincas recorrentes" do
        recurrent = @result[:triples][:recurrent]

        assert_equal 1, recurrent.size
        assert_equal [1, 2, 3], recurrent.first[:numbers]
        assert_equal 2, recurrent.first[:occurrence_count]
      end

      test "identifica combinações completas distintas" do
        combinations = @result[:complete_combinations]

        assert_equal 50_063_860, combinations[:total_possible]
        assert_equal 3, combinations[:distinct_observed]
        assert_equal 0, combinations[:repeated_count]
        assert_equal 3, combinations[:single_occurrence_count]
      end

      test "identifica combinações completas recorrentes" do
        create_draw(4, [1, 4, 7, 10, 11, 12])

        result = CombinationAnalyzer.new(
          dataset: Dataset.new
        ).call

        combinations = result[:complete_combinations]

        assert_equal 3, combinations[:distinct_observed]
        assert_equal 1, combinations[:repeated_count]

        recurrent = combinations[:recurrent].first

        assert_equal [1, 4, 7, 10, 11, 12], recurrent[:numbers]
        assert_equal 2, recurrent[:occurrence_count]
      end

      test "identifica dezenas repetidas entre concursos consecutivos" do
        transitions = @result[:consecutive_draws]

        assert_equal 2, transitions[:total_transitions]

        first_transition = transitions[:data][0]
        second_transition = transitions[:data][1]

        assert_equal [1, 2, 3], first_transition[:repeated_numbers]
        assert_equal 3, first_transition[:repeated_count]

        assert_equal [1, 7], second_transition[:repeated_numbers]
        assert_equal 2, second_transition[:repeated_count]
      end

      test "calcula a distribuição de dezenas repetidas" do
        distribution = @result[:consecutive_draws][:distribution]

        assert_equal 7, distribution.size

        two_repeated = distribution.find do |item|
          item[:repeated_count] == 2
        end

        three_repeated = distribution.find do |item|
          item[:repeated_count] == 3
        end

        assert_equal 1, two_repeated[:transition_count]
        assert_equal 1, three_repeated[:transition_count]

        assert_in_delta 50.0, two_repeated[:percentage], 0.001
        assert_in_delta 50.0, three_repeated[:percentage], 0.001
      end

      test "calcula os indicadores das transições consecutivas" do
        transitions = @result[:consecutive_draws]

        assert_equal 2, transitions[:total_transitions]
        assert_equal 2, transitions[:transitions_with_repetitions]
        assert_equal 0, transitions[:transitions_without_repetitions]

        assert_in_delta 2.5, transitions[:average_repeated_numbers], 0.001
        assert_equal 3, transitions[:maximum_repeated_numbers]
      end

      test "ordena pares e trincas por frequência" do
        pairs = @result[:rankings][:most_frequent_pairs]
        triples = @result[:rankings][:most_frequent_triples]

        assert_equal 2, pairs.first[:occurrence_count]
        assert_equal 2, triples.first[:occurrence_count]

        assert_equal [1, 2], pairs.first[:numbers]
        assert_equal [1, 2, 3], triples.first[:numbers]
      end

      test "retorna indicadores gerais consistentes" do
        metrics = @result[:metrics]

        assert_equal 3, metrics[:total_draws]
        assert_equal 45, metrics[:total_pair_occurrences]
        assert_equal 60, metrics[:total_triple_occurrences]

        assert_equal 40, metrics[:distinct_pairs_observed]
        assert_equal 59, metrics[:distinct_triples_observed]

        assert_equal 5, metrics[:recurrent_pairs]
        assert_equal 1, metrics[:recurrent_triples]

        assert_equal 3, metrics[:distinct_complete_combinations]
        assert_equal 0, metrics[:recurrent_complete_combinations]

        assert_equal 2, metrics[:total_consecutive_transitions]
        assert_in_delta 2.5, metrics[:average_repeated_numbers], 0.001
        assert_equal 3, metrics[:maximum_repeated_numbers]
      end

      test "trata corretamente um dataset vazio" do
        result = CombinationAnalyzer.new(
          dataset: Dataset.new(relation: Draw.none)
        ).call

        assert_equal 0, result[:total_draws]

        assert_equal 0, result[:pairs][:total_occurrences]
        assert_empty result[:pairs][:data]
        assert_empty result[:pairs][:recurrent]

        assert_equal 0, result[:triples][:total_occurrences]
        assert_empty result[:triples][:data]
        assert_empty result[:triples][:recurrent]

        assert_equal 0, result[:complete_combinations][:distinct_observed]
        assert_empty result[:complete_combinations][:data]
        assert_empty result[:complete_combinations][:recurrent]

        transitions = result[:consecutive_draws]

        assert_equal 0, transitions[:total_transitions]
        assert_nil transitions[:average_repeated_numbers]
        assert_nil transitions[:maximum_repeated_numbers]
        assert_empty transitions[:data]

        assert_equal 7, transitions[:distribution].size

        assert transitions[:distribution].all? do |item|
          item[:transition_count].zero? &&
            item[:percentage].zero?
        end
      end

      test "trata dataset com apenas um concurso" do
        result = CombinationAnalyzer.new(
          dataset: Dataset.new(
            relation: Draw.where(contest_number: 1)
          )
        ).call

        transitions = result[:consecutive_draws]

        assert_equal 0, transitions[:total_transitions]
        assert_nil transitions[:average_repeated_numbers]
        assert_nil transitions[:maximum_repeated_numbers]
      end

      private

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
