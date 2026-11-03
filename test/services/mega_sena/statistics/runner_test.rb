
# frozen_string_literal: true

require "test_helper"

module MegaSena
  module Statistics
    class RunnerTest < ActiveSupport::TestCase
      setup do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 7, 8, 9])
        create_draw(3, [1, 4, 7, 10, 11, 12])
      end

      test "executa todos os analisadores por padrão" do
        result = Runner.new.call

        assert_equal Runner::DEFAULT_ANALYZERS, result[:analyses].keys
      end

      test "retorna a estrutura consolidada" do
        result = Runner.new.call

        assert result[:generated_at].present?

        assert_equal 3, result[:dataset][:total_draws]
        assert_equal 1, result[:dataset][:first_contest_number]
        assert_equal 3, result[:dataset][:last_contest_number]

        assert_equal 6, result[:analyses].size
      end

      test "executa somente os analisadores solicitados" do
        result = Runner.new(
          analyzer_names: %i[frequency parity]
        ).call

        assert_equal %i[frequency parity], result[:analyses].keys

        assert result[:analyses].key?(:frequency)
        assert result[:analyses].key?(:parity)

        assert_not result[:analyses].key?(:sum)
        assert_not result[:analyses].key?(:sequence)
        assert_not result[:analyses].key?(:delay)
        assert_not result[:analyses].key?(:combination)
      end

      test "aceita nomes de analisadores como strings" do
        result = Runner.new(
          analyzer_names: %w[frequency delay]
        ).call

        assert_equal %i[frequency delay], result[:analyses].keys
      end

      test "rejeita analisadores desconhecidos" do
        error = assert_raises(ArgumentError) do
          Runner.new(
            analyzer_names: %i[frequency unknown]
          )
        end

        assert_includes error.message, "unknown"
      end

      test "aceita um dataset fornecido externamente" do
        dataset = Dataset.new(
          relation: Draw.where(contest_number: 1..2)
        )

        runner = Runner.new(
          dataset: dataset,
          analyzer_names: %i[frequency]
        )

        result = runner.call

        assert_same dataset, runner.dataset
        assert_equal 2, result[:dataset][:total_draws]
        assert_equal 1, result[:dataset][:first_contest_number]
        assert_equal 2, result[:dataset][:last_contest_number]
      end

      test "aceita uma relação filtrada" do
        result = Runner.new(
          relation: Draw.where(contest_number: 2..3),
          analyzer_names: %i[frequency parity]
        ).call

        assert_equal 2, result[:dataset][:total_draws]
        assert_equal 2, result[:dataset][:first_contest_number]
        assert_equal 3, result[:dataset][:last_contest_number]
      end

      test "trata corretamente um dataset vazio" do
        result = Runner.new(
          relation: Draw.none
        ).call

        assert_equal 0, result[:dataset][:total_draws]
        assert_nil result[:dataset][:first_contest_number]
        assert_nil result[:dataset][:last_contest_number]

        assert_equal 6, result[:analyses].size
      end

      test "preserva a ordem solicitada dos analisadores" do
        result = Runner.new(
          analyzer_names: %i[combination frequency delay]
        ).call

        assert_equal(
          %i[combination frequency delay],
          result[:analyses].keys
        )
      end

      test "permite executar sem analisadores" do
        result = Runner.new(
          analyzer_names: []
        ).call

        assert_empty result[:analyses]
        assert_equal 3, result[:dataset][:total_draws]
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
