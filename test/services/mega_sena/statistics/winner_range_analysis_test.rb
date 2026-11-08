
require "test_helper"

class MegaSena::Statistics::WinnerRangeAnalysisTest < ActiveSupport::TestCase
  setup do
    Draw.delete_all

    create_draw(
      contest_number: 1,
      winners_sena: 0,
      numbers: [1, 2, 3, 4, 5, 6]
    )

    create_draw(
      contest_number: 2,
      winners_sena: 1,
      numbers: [1, 7, 8, 9, 10, 11]
    )

    create_draw(
      contest_number: 3,
      winners_sena: 3,
      numbers: [2, 7, 12, 13, 14, 15]
    )

    create_draw(
      contest_number: 4,
      winners_sena: 5,
      numbers: [20, 21, 22, 23, 24, 25]
    )
  end

  test "conta aparições e não aparições dentro da faixa informada" do
    result = analysis(minimum: 0, maximum: 1).call

    assert_equal 2, result[:total_draws]

    number_1 = result[:numbers].find { |item| item[:number] == 1 }

    assert_equal 2, number_1[:appearances]
    assert_equal 0, number_1[:non_appearances]
    assert_equal 100.0, number_1[:appearance_percentage]

    number_2 = result[:numbers].find { |item| item[:number] == 2 }

    assert_equal 1, number_2[:appearances]
    assert_equal 1, number_2[:non_appearances]
  end

  test "considera os limites mínimo e máximo como inclusivos" do
    result = analysis(minimum: 1, maximum: 3).call

    assert_equal 2, result[:total_draws]
  end

  test "retorna as 60 dezenas" do
    result = analysis(minimum: 0, maximum: 5).call

    assert_equal 60, result[:numbers].size
    assert_equal (1..60).to_a, result[:numbers].map { |item| item[:number] }
  end

  test "calcula zero aparições quando a dezena não aparece" do
    result = analysis(minimum: 0, maximum: 0).call

    number_60 = result[:numbers].find { |item| item[:number] == 60 }

    assert_equal 0, number_60[:appearances]
    assert_equal 1, number_60[:non_appearances]
    assert_equal 0.0, number_60[:appearance_percentage]
    assert_equal 100.0, number_60[:non_appearance_percentage]
  end

  test "retorna resultado vazio quando nenhum concurso atende à faixa" do
    result = analysis(minimum: 10, maximum: 20).call

    assert_equal 0, result[:total_draws]
    assert_equal 60, result[:numbers].size
    assert result[:numbers].all? { |item| item[:appearances].zero? }
  end

  test "rejeita faixa com mínimo maior que máximo" do
    assert_raises(ArgumentError) do
      analysis(minimum: 5, maximum: 2)
    end
  end

  test "rejeita quantidade negativa de ganhadores" do
    assert_raises(ArgumentError) do
      analysis(minimum: -1, maximum: 2)
    end
  end

  private

  def analysis(minimum:, maximum:)
    MegaSena::Statistics::WinnerRangeAnalysis.new(
      minimum_winners: minimum,
      maximum_winners: maximum
    )
  end

  def create_draw(contest_number:, winners_sena:, numbers:)
    Draw.create!(
      contest_number: contest_number,
      draw_date: Date.new(2025, 1, contest_number),
      number_1: numbers[0],
      number_2: numbers[1],
      number_3: numbers[2],
      number_4: numbers[3],
      number_5: numbers[4],
      number_6: numbers[5],
      winners_sena: winners_sena
    )
  end
end
