require "test_helper"

class ViradaAnalysesControllerTest < ActionDispatch::IntegrationTest
  def create_draw(contest, date, numbers, winners: nil)
    attrs = { contest_number: contest, draw_date: date, winners_sena: winners }
    %i[number_1 number_2 number_3 number_4 number_5 number_6].each_with_index { |column, i| attrs[column] = numbers[i] }
    Draw.create!(attrs)
  end

  test "sem edições mostra aviso" do
    get virada_analyses_path

    assert_response :success
    assert_match(/Nenhum concurso da Mega da Virada/, response.body)
  end

  test "lista as edições e o histórico das 60 dezenas" do
    create_draw(3, Date.new(2009, 12, 31), [ 10, 27, 40, 46, 49, 58 ], winners: 2)
    create_draw(5, Date.new(2010, 12, 31), [ 2, 10, 34, 37, 43, 50 ], winners: 4)
    create_draw(6, Date.new(2011, 1, 5), [ 1, 2, 3, 4, 5, 6 ])   # comum: fora da Virada

    get virada_analyses_path

    assert_response :success
    assert_match(/Dezenas sorteadas em cada edição/, response.body)
    assert_match(/Histórico de cada dezena nas Viradas/, response.body)
    assert_match(/#5/, response.body)
    assert_match(/saiu na última edição/, response.body)
    assert_match(/nunca saiu/, response.body)
    assert_select "section:last-of-type tbody tr", 60
  end

  test "aceita ordenação e ignora valores inválidos" do
    create_draw(3, Date.new(2009, 12, 31), [ 10, 27, 40, 46, 49, 58 ], winners: 2)

    %w[number times delay].each do |sort|
      get virada_analyses_path(sort: sort)
      assert_response :success
    end

    get virada_analyses_path(sort: "xyz")
    assert_response :success
  end
end
