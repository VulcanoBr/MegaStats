
# frozen_string_literal: true

require "test_helper"

module MegaSena
  class CombinationAnalyzerTest < ActiveSupport::TestCase
    setup do
      create_draw(1, [1, 2, 3, 4, 5, 6])
      create_draw(2, [1, 2, 3, 7, 8, 9])
      create_draw(3, [1, 4, 7, 10, 11, 12])
    end

    test "identifica uma combinação existente no histórico" do
      result = CombinationAnalyzer.new(
        numbers: [6, 4, 2, 5, 1, 3]
      ).call

      assert_equal [1, 2, 3, 4, 5, 6], result[:numbers]
      assert_equal 1, result[:historical_occurrences]
      assert_equal [1], result[:contests]
      assert_equal "1 em 50063860", result[:theoretical_probability]
    end

    test "identifica uma combinação inexistente no histórico" do
      result = CombinationAnalyzer.new(
        numbers: [13, 14, 15, 16, 17, 18]
      ).call

      assert_equal 0, result[:historical_occurrences]
      assert_empty result[:contests]
    end

    test "rejeita combinações com menos de seis números" do
      assert_raises(ArgumentError) do
        CombinationAnalyzer.new(
          numbers: [1, 2, 3, 4, 5]
        )
      end
    end

    test "rejeita combinações com mais de seis números" do
      assert_raises(ArgumentError) do
        CombinationAnalyzer.new(
          numbers: [1, 2, 3, 4, 5, 6, 7]
        )
      end
    end

    test "rejeita números repetidos" do
      error = assert_raises(ArgumentError) do
        CombinationAnalyzer.new(
          numbers: [1, 2, 3, 4, 5, 5]
        )
      end

      assert_equal(
        "Informe exatamente seis números distintos entre 1 e 60.",
        error.message
      )
    end

    test "rejeita números menores que um" do
      assert_raises(ArgumentError) do
        CombinationAnalyzer.new(
          numbers: [0, 2, 3, 4, 5, 6]
        )
      end
    end

    test "rejeita números maiores que sessenta" do
      assert_raises(ArgumentError) do
        CombinationAnalyzer.new(
          numbers: [1, 2, 3, 4, 5, 61]
        )
      end
    end

    test "rejeita valores que não podem ser convertidos em inteiros" do
      assert_raises(ArgumentError) do
        CombinationAnalyzer.new(
          numbers: [1, 2, 3, 4, 5, "abc"]
        )
      end
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
