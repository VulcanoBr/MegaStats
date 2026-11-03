
# frozen_string_literal: true

require "test_helper"

module MegaSena
  class LeastFrequentGeneratorTest < ActiveSupport::TestCase
    setup do
      # Combinação A: aparece duas vezes.
      create_draw(1, [1, 2, 3, 4, 5, 6])
      create_draw(2, [1, 2, 3, 4, 5, 6])

      # Combinação B: aparece uma vez.
      create_draw(3, [1, 2, 3, 7, 8, 9])

      # Combinação C: aparece três vezes.
      create_draw(4, [1, 4, 7, 10, 11, 12])
      create_draw(5, [1, 4, 7, 10, 11, 12])
      create_draw(6, [1, 4, 7, 10, 11, 12])
    end

    test "retorna a quantidade solicitada de combinações" do
      combinations = LeastFrequentGenerator.new(
        quantity: 2
      ).call

      assert_equal 2, combinations.size
    end

    test "ordena as combinações por frequência crescente" do
      combinations = LeastFrequentGenerator.new.call

      frequencies = combinations.map do |item|
        item[:historical_occurrences]
      end

      assert_equal [1, 2, 3], frequencies
    end

    test "retorna primeiro a combinação que ocorreu uma vez" do
      combinations = LeastFrequentGenerator.new.call

      assert_equal(
        [1, 2, 3, 7, 8, 9],
        combinations.first[:numbers]
      )

      assert_equal 1, combinations.first[:historical_occurrences]
    end

    test "desempata pela ordem crescente das dezenas" do
      create_draw(7, [2, 3, 4, 5, 6, 7])

      combinations = LeastFrequentGenerator.new.call

      tied_combinations = combinations.select do |item|
        item[:historical_occurrences] == 1
      end

      assert_equal(
        [
          [1, 2, 3, 7, 8, 9],
          [2, 3, 4, 5, 6, 7]
        ],
        tied_combinations.map { |item| item[:numbers] }
      )
    end

    test "retorna as dezenas ordenadas em cada combinação" do
      combinations = LeastFrequentGenerator.new.call

      combinations.each do |item|
        assert_equal item[:numbers].sort, item[:numbers]
      end
    end

    test "rejeita quantidade menor que um" do
      assert_raises(ArgumentError) do
        LeastFrequentGenerator.new(quantity: 0)
      end
    end

    test "rejeita quantidade maior que cem" do
      assert_raises(ArgumentError) do
        LeastFrequentGenerator.new(quantity: 101)
      end
    end

    test "rejeita quantidade que não seja numérica" do
      assert_raises(ArgumentError) do
        LeastFrequentGenerator.new(quantity: "abc")
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
