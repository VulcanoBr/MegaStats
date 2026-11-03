
# frozen_string_literal: true

require "test_helper"

module MegaSena
  class UnseenCombinationGeneratorTest < ActiveSupport::TestCase
    setup do
      create_draw(1, [1, 2, 3, 4, 5, 6])
      create_draw(2, [1, 2, 3, 7, 8, 9])
      create_draw(3, [1, 4, 7, 10, 11, 12])
    end

    test "gera a quantidade solicitada de combinações" do
      combinations = UnseenCombinationGenerator.new(
        quantity: 5
      ).call

      assert_equal 5, combinations.size
    end

    test "gera combinações com exatamente seis dezenas" do
      combinations = UnseenCombinationGenerator.new(
        quantity: 5
      ).call

      combinations.each do |numbers|
        assert_equal 6, numbers.size
        assert_equal 6, numbers.uniq.size
      end
    end

    test "gera somente dezenas entre um e sessenta" do
      combinations = UnseenCombinationGenerator.new(
        quantity: 5
      ).call

      combinations.flatten.each do |number|
        assert_includes 1..60, number
      end
    end

    test "não gera combinações presentes no histórico" do
      existing_combinations = [
        [1, 2, 3, 4, 5, 6],
        [1, 2, 3, 7, 8, 9],
        [1, 4, 7, 10, 11, 12]
      ]

      combinations = UnseenCombinationGenerator.new(
        quantity: 5
      ).call

      combinations.each do |numbers|
        assert_not_includes existing_combinations, numbers
      end
    end

    test "não gera combinações duplicadas" do
      combinations = UnseenCombinationGenerator.new(
        quantity: 10
      ).call

      assert_equal combinations.size, combinations.uniq.size
    end

    test "retorna combinações ordenadas internamente" do
      combinations = UnseenCombinationGenerator.new(
        quantity: 5
      ).call

      combinations.each do |numbers|
        assert_equal numbers.sort, numbers
      end
    end

    test "rejeita quantidade menor que um" do
      assert_raises(ArgumentError) do
        UnseenCombinationGenerator.new(quantity: 0)
      end
    end

    test "rejeita quantidade maior que cem" do
      assert_raises(ArgumentError) do
        UnseenCombinationGenerator.new(quantity: 101)
      end
    end

    test "rejeita quantidade que não seja numérica" do
      assert_raises(ArgumentError) do
        UnseenCombinationGenerator.new(quantity: "abc")
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
