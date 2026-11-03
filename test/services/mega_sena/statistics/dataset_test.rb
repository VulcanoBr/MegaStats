
require "test_helper"

module MegaSena
  module Statistics
    class DatasetTest < ActiveSupport::TestCase
      test "carrega os concursos em ordem crescente" do
        create_draw(2, [10, 11, 12, 13, 14, 15])
        create_draw(1, [1, 2, 3, 4, 5, 6])

        dataset = Dataset.new

        assert_equal [1, 2], dataset.contest_numbers
      end

      test "disponibiliza as seis dezenas ordenadas" do
        create_draw(1, [30, 10, 50, 20, 60, 40])

        dataset = Dataset.new

        assert_equal [10, 20, 30, 40, 50, 60],
                     dataset.draws.first.numbers
      end

      test "informa a quantidade de concursos" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [7, 8, 9, 10, 11, 12])

        dataset = Dataset.new

        assert_equal 2, dataset.total_draws
      end

      test "disponibiliza o primeiro e o último concurso" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(3, [7, 8, 9, 10, 11, 12])

        dataset = Dataset.new

        assert_equal 1, dataset.first_contest_number
        assert_equal 3, dataset.last_contest_number
      end

      test "retorna conjunto vazio quando não existem concursos" do
        dataset = Dataset.new(relation: Draw.none)

        assert dataset.empty?
        assert_equal 0, dataset.total_draws
        assert_nil dataset.first_contest_number
        assert_nil dataset.last_contest_number
        assert_empty dataset.numbers
      end

      test "permite trabalhar com uma relação filtrada" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [7, 8, 9, 10, 11, 12])
        create_draw(3, [13, 14, 15, 16, 17, 18])

        dataset = Dataset.new(
          relation: Draw.where(contest_number: 2..3)
        )

        assert_equal [2, 3], dataset.contest_numbers
      end

      test "mantém a fotografia carregada imutável" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        dataset = Dataset.new

        assert_predicate dataset.draws, :frozen?
        assert_predicate dataset.draws.first, :frozen?
        assert_predicate dataset.draws.first.numbers, :frozen?
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
