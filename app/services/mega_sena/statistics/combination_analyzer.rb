
# frozen_string_literal: true

module MegaSena
  module Statistics
    class CombinationAnalyzer
      TOTAL_NUMBERS = 60
      NUMBERS_PER_DRAW = 6

      PAIRS_PER_DRAW = 15
      TRIPLES_PER_DRAW = 20

      TOTAL_POSSIBLE_PAIRS = 1_770
      TOTAL_POSSIBLE_TRIPLES = 34_220
      TOTAL_POSSIBLE_COMBINATIONS = 50_063_860

      attr_reader :dataset

      def initialize(dataset:)
        @dataset = dataset
      end

      def call
        {
          total_draws: dataset.total_draws,
          analyzed_at: Time.current,
          metrics: metrics,
          pairs: pair_analysis,
          triples: triple_analysis,
          complete_combinations: complete_combination_analysis,
          consecutive_draws: consecutive_draw_analysis,
          rankings: rankings
        }
      end

      private

      # -----------------------------------------------------------------------
      # PARES
      # -----------------------------------------------------------------------

      def pair_analysis
        @pair_analysis ||= build_combination_analysis(
          combination_size: 2,
          total_possible: TOTAL_POSSIBLE_PAIRS
        )
      end

      # -----------------------------------------------------------------------
      # TRINCAS
      # -----------------------------------------------------------------------

      def triple_analysis
        @triple_analysis ||= build_combination_analysis(
          combination_size: 3,
          total_possible: TOTAL_POSSIBLE_TRIPLES
        )
      end

      # -----------------------------------------------------------------------
      # COMBINAÇÕES COMPLETAS
      # -----------------------------------------------------------------------

      def complete_combination_analysis
        @complete_combination_analysis ||= begin
          counts = Hash.new(0)

          dataset.draws.each do |draw|
            combination = draw.numbers.sort.freeze
            counts[combination] += 1
          end

          data = build_frequency_data(counts)

          {
            total_possible: TOTAL_POSSIBLE_COMBINATIONS,
            distinct_observed: data.size,
            repeated_count: data.count { |item| item[:occurrence_count] > 1 },
            single_occurrence_count: data.count do |item|
              item[:occurrence_count] == 1
            end,
            data: data,
            recurrent: data.select do |item|
              item[:occurrence_count] > 1
            end.sort_by do |item|
              [-item[:occurrence_count], item[:numbers]]
            end
          }
        end
      end

      # -----------------------------------------------------------------------
      # ANÁLISE GENÉRICA DE PARES E TRINCAS
      # -----------------------------------------------------------------------

      def build_combination_analysis(combination_size:, total_possible:)
        counts = Hash.new(0)

        dataset.draws.each do |draw|
          draw.numbers
              .combination(combination_size)
              .each do |combination|
            counts[combination.freeze] += 1
          end
        end

        data = build_frequency_data(counts)

        {
          total_possible: total_possible,
          total_occurrences: counts.values.sum,
          distinct_observed: data.size,
          repeated_count: data.count { |item| item[:occurrence_count] > 1 },
          single_occurrence_count: data.count do |item|
            item[:occurrence_count] == 1
          end,
          data: data,
          recurrent: data.select do |item|
            item[:occurrence_count] > 1
          end.sort_by do |item|
            [-item[:occurrence_count], item[:numbers]]
          end
        }
      end

      def build_frequency_data(counts)
        counts.map do |numbers, occurrence_count|
          {
            numbers: numbers,
            occurrence_count: occurrence_count,
            percentage: percentage(occurrence_count, dataset.total_draws)
          }
        end.sort_by do |item|
          item[:numbers]
        end
      end

      # -----------------------------------------------------------------------
      # REPETIÇÃO ENTRE CONCURSOS CONSECUTIVOS
      # -----------------------------------------------------------------------

      def consecutive_draw_analysis
        @consecutive_draw_analysis ||= begin
          transitions = build_consecutive_transitions
          distribution = consecutive_repeat_distribution(transitions)

          {
            total_transitions: transitions.size,
            transitions_with_repetitions: transitions.count do |item|
              item[:repeated_count].positive?
            end,
            transitions_without_repetitions: transitions.count do |item|
              item[:repeated_count].zero?
            end,
            average_repeated_numbers: average(
              transitions.map { |item| item[:repeated_count] }
            ),
            maximum_repeated_numbers: transitions.map do |item|
              item[:repeated_count]
            end.max,
            distribution: distribution,
            data: transitions
          }
        end
      end

      def build_consecutive_transitions
        dataset.draws.each_cons(2).map do |previous_draw, current_draw|
          repeated_numbers = (
            previous_draw.numbers & current_draw.numbers
          ).sort

          {
            previous_contest: previous_draw.contest_number,
            current_contest: current_draw.contest_number,
            repeated_numbers: repeated_numbers,
            repeated_count: repeated_numbers.size
          }
        end
      end

      def consecutive_repeat_distribution(transitions)
        (0..NUMBERS_PER_DRAW).map do |quantity|
          count = transitions.count do |item|
            item[:repeated_count] == quantity
          end

          {
            repeated_count: quantity,
            transition_count: count,
            percentage: percentage(count, transitions.size)
          }
        end
      end

      # -----------------------------------------------------------------------
      # INDICADORES GERAIS
      # -----------------------------------------------------------------------

      def metrics
        {
          total_draws: dataset.total_draws,
          total_pair_occurrences: pair_analysis[:total_occurrences],
          total_triple_occurrences: triple_analysis[:total_occurrences],

          distinct_pairs_observed: pair_analysis[:distinct_observed],
          distinct_triples_observed: triple_analysis[:distinct_observed],

          recurrent_pairs: pair_analysis[:repeated_count],
          recurrent_triples: triple_analysis[:repeated_count],

          distinct_complete_combinations:
            complete_combination_analysis[:distinct_observed],

          recurrent_complete_combinations:
            complete_combination_analysis[:repeated_count],

          total_consecutive_transitions:
            consecutive_draw_analysis[:total_transitions],

          average_repeated_numbers:
            consecutive_draw_analysis[:average_repeated_numbers],

          maximum_repeated_numbers:
            consecutive_draw_analysis[:maximum_repeated_numbers]
        }
      end

      # -----------------------------------------------------------------------
      # RANKINGS
      # -----------------------------------------------------------------------

      def rankings
        {
          most_frequent_pairs: frequency_ranking(pair_analysis[:data]),
          most_frequent_triples: frequency_ranking(triple_analysis[:data]),

          most_frequent_complete_combinations: frequency_ranking(
            complete_combination_analysis[:data]
          ),

          most_repeated_between_consecutive_draws:
            consecutive_draw_analysis[:data].sort_by do |item|
              [
                -item[:repeated_count],
                item[:current_contest]
              ]
            end
        }
      end

      def frequency_ranking(data)
        data.sort_by do |item|
          [
            -item[:occurrence_count],
            item[:numbers]
          ]
        end
      end

      # -----------------------------------------------------------------------
      # FUNÇÕES AUXILIARES
      # -----------------------------------------------------------------------

      def percentage(value, total)
        return 0.0 if total.zero?

        value.fdiv(total) * 100
      end

      def average(values)
        return nil if values.empty?

        values.sum.fdiv(values.size)
      end
    end
  end
end
