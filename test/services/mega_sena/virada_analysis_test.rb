require "test_helper"

class MegaSena::ViradaAnalysisTest < ActiveSupport::TestCase
  def create_draw(contest, date, numbers, winners: nil, prize: nil)
    attrs = { contest_number: contest, draw_date: date, winners_sena: winners, prize_sena: prize }
    %i[number_1 number_2 number_3 number_4 number_5 number_6].each_with_index { |column, i| attrs[column] = numbers[i] }
    Draw.create!(attrs)
  end

  setup do
    create_draw(1, Date.new(2008, 12, 31), [ 1, 2, 3, 4, 5, 6 ], winners: 0)                      # antes da 1ª edição oficial
    create_draw(2, Date.new(2009, 12, 26), [ 7, 8, 9, 10, 11, 12 ])                                # sorteio comum
    create_draw(3, Date.new(2009, 12, 31), [ 58, 49, 46, 40, 27, 10 ], winners: 2, prize: 72_000_000) # Virada 2009
    create_draw(4, Date.new(2010, 1, 2), [ 9, 37, 40, 50, 58, 60 ])                                # sorteio comum
    create_draw(5, Date.new(2010, 12, 31), [ 2, 10, 34, 37, 43, 50 ], winners: 4)                  # Virada 2010
    create_draw(6, Date.new(2011, 6, 1), [ 1, 2, 3, 4, 5, 6 ])                                     # sorteio comum
    create_draw(7, Date.new(2011, 12, 31), [ 3, 4, 29, 36, 45, 55 ], winners: 5)                   # Virada 2011
    create_draw(8, Date.new(2026, 1, 1), [ 9, 13, 21, 32, 33, 59 ], winners: 6)                    # Virada 2025 (datada de 01/01/2026)
    @result = MegaSena::ViradaAnalysis.new.call
  end

  test "identifica as edições pela data (31/12 ou 01/01 a partir de 31/12/2009)" do
    assert_equal [ 3, 5, 7, 8 ], @result.editions.map(&:contest_number)
    assert_equal [ 1, 2, 3, 4 ], @result.editions.map(&:edition)
    assert_equal 4, @result.total_editions
    assert_equal 8, @result.latest.contest_number
  end

  test "ignora o 31/12 anterior à primeira edição e os sorteios comuns" do
    contests = @result.editions.map(&:contest_number)

    assert_not_includes contests, 1   # 31/12/2008
    assert_not_includes contests, 2
    assert_not_includes contests, 4
    assert_not_includes contests, 6
  end

  test "o sorteio de 01/01 pertence à Virada do ano anterior" do
    assert_equal [ 2009, 2010, 2011, 2025 ], @result.editions.map(&:year)
  end

  test "dezenas de cada edição em ordem crescente, com ganhadores e prêmio" do
    first = @result.editions.first

    assert_equal [ 10, 27, 40, 46, 49, 58 ], first.numbers
    assert_equal 2, first.winners_sena
    assert_equal 72_000_000, first.prize_sena
  end

  test "vezes sorteada nas Viradas" do
    stats = @result.number_stats.index_by(&:number)

    assert_equal 60, @result.number_stats.size
    assert_equal 2, stats[10].times_drawn          # Viradas 1 e 2
    assert_in_delta 50.0, stats[10].percent_of_editions, 0.001
    assert_equal 1, stats[3].times_drawn
    assert_equal 1, stats[2].times_drawn           # o 2 do concurso 1 (2008) não conta
    assert_equal 0, stats[1].times_drawn           # só saiu em concursos fora da Virada
    assert_equal 0, stats[7].times_drawn
  end

  test "edições sem sair desde a última aparição" do
    stats = @result.number_stats.index_by(&:number)

    assert_equal 2, stats[10].editions_since_last  # última na edição 2; total 4
    assert_equal 2, stats[10].last_edition
    assert_equal 5, stats[10].last_contest
    assert_equal Date.new(2010, 12, 31), stats[10].last_date

    assert_equal 1, stats[3].editions_since_last   # última na edição 3
    assert_equal 0, stats[9].editions_since_last   # saiu na edição mais recente (4)
    assert stats[9].drawn_in_latest?
    assert_equal 3, stats[58].editions_since_last  # só na edição 1
  end

  test "dezena que nunca saiu conta todas as edições" do
    stat = @result.number_stats.find { |s| s.number == 1 }

    assert stat.never_drawn?
    assert_equal 4, stat.editions_since_last
    assert_nil stat.last_edition
    assert_nil stat.last_contest
    assert_nil stat.last_date
    assert_not stat.drawn_in_latest?
  end

  test "resumo" do
    assert_includes @result.never_drawn_numbers, 1
    assert_not_includes @result.never_drawn_numbers, 10
    assert_equal 60, @result.distinct_numbers_drawn + @result.never_drawn_numbers.size
  end

  test "sem edições cadastradas" do
    Draw.delete_all
    result = MegaSena::ViradaAnalysis.new.call

    assert_empty result.editions
    assert_equal 0, result.total_editions
    assert_nil result.latest
    assert_equal 60, result.never_drawn_numbers.size
  end

  test "data especial" do
    assert MegaSena::ViradaAnalysis.special_date?(Date.new(2030, 12, 31))
    assert MegaSena::ViradaAnalysis.special_date?(Date.new(2031, 1, 1))
    assert_not MegaSena::ViradaAnalysis.special_date?(Date.new(2030, 12, 30))
  end
end
