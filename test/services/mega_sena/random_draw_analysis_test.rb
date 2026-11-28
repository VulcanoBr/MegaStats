require "test_helper"

class MegaSena::RandomDrawAnalysisTest < ActiveSupport::TestCase
  def create_draw(contest, numbers)
    attrs = { contest_number: contest, draw_date: Date.new(2020, 1, 1) + contest }
    %i[number_1 number_2 number_3 number_4 number_5 number_6].each_with_index { |column, i| attrs[column] = numbers[i] }
    Draw.create!(attrs)
  end

  setup do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])
    create_draw(3, [ 10, 11, 12, 13, 14, 15 ])
    create_draw(4, [ 1, 20, 21, 22, 23, 24 ])
  end

  def analyze(numbers)
    MegaSena::RandomDrawAnalysis.new(numbers).call
  end

  test "dados gerais do histórico" do
    result = analyze([ 1, 2, 3, 4, 5, 6 ])

    assert_equal 4, result.total_draws
    assert_equal 4, result.latest_contest
    assert_equal Date.new(2020, 1, 5), result.latest_date
  end

  test "vezes sorteada, último concurso e concursos sem sair" do
    stats = analyze([ 1, 2, 3, 4, 5, 6 ]).number_stats.index_by(&:number)

    assert_equal 3, stats[1].times_drawn            # concursos 1, 2 e 4
    assert_equal 4, stats[1].last_contest
    assert_equal 0, stats[1].draws_since_last
    assert stats[1].drawn_in_latest?
    assert_in_delta 75.0, stats[1].percent_of_draws, 0.001
    assert_in_delta 1.5, stats[1].average_gap, 0.001  # (4 - 1) / (3 - 1)

    assert_equal 2, stats[2].times_drawn            # concursos 1 e 2
    assert_equal 2, stats[2].last_contest
    assert_equal 2, stats[2].draws_since_last       # 4 - 2
    assert_in_delta 1.0, stats[2].average_gap, 0.001

    assert_equal 1, stats[4].times_drawn
    assert_equal 3, stats[4].draws_since_last       # 4 - 1
    assert_nil stats[4].average_gap
    assert_equal Date.new(2020, 1, 2), stats[4].last_date
  end

  test "dezena que nunca saiu" do
    stat = analyze([ 1, 2, 3, 4, 5, 60 ]).number_stats.find { |s| s.number == 60 }

    assert stat.never_drawn?
    assert_equal 0, stat.times_drawn
    assert_nil stat.last_contest
    assert_nil stat.draws_since_last
    assert_nil stat.average_gap
  end

  test "combinação já sorteada" do
    result = analyze([ 6, 5, 4, 3, 2, 1 ])   # ordem de entrada não importa

    assert result.already_drawn?
    assert_equal [ 1 ], result.combination_matches.map(&:contest_number)
    assert_equal 6, result.best_hits
  end

  test "combinação nunca sorteada informa o maior acerto histórico" do
    result = analyze([ 1, 2, 3, 4, 5, 60 ])

    assert_not result.already_drawn?
    assert_equal 5, result.best_hits
    assert_equal [ 1 ], result.best_matches.map(&:contest_number)
    assert_equal [ 1, 2, 3, 4, 5 ], result.best_matches.first.hits
  end

  test "empates no maior acerto listam todos os concursos" do
    result = analyze([ 1, 2, 3, 30, 31, 32 ])  # 3 acertos nos concursos 1 e 2

    assert_equal 3, result.best_hits
    assert_equal [ 1, 2 ], result.best_matches.map(&:contest_number)
  end

  test "sem concursos cadastrados" do
    Draw.delete_all
    result = analyze([ 1, 2, 3, 4, 5, 6 ])

    assert_equal 0, result.total_draws
    assert_nil result.latest_contest
    assert_not result.already_drawn?
    assert(result.number_stats.all?(&:never_drawn?))
  end
end
