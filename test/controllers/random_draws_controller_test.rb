require "test_helper"

class RandomDrawsControllerTest < ActionDispatch::IntegrationTest
  def create_draw(contest, numbers)
    attrs = { contest_number: contest, draw_date: Date.new(2020, 1, 1) + contest }
    %i[number_1 number_2 number_3 number_4 number_5 number_6].each_with_index { |column, i| attrs[column] = numbers[i] }
    Draw.create!(attrs)
  end

  test "tela inicial" do
    get random_draw_path
    assert_response :success
    assert_select "form[action=?]", random_draw_path
    assert_match(/Sortear 6 dezenas/, response.body)
  end

  test "sortear redireciona com seis dezenas distintas na URL" do
    post random_draw_path

    assert_response :see_other
    assert_match(/numbers=(\d{2}-){5}\d{2}\z/, response.location)

    numbers = Rack::Utils.parse_query(URI(response.location).query)["numbers"].split("-").map(&:to_i)
    assert_equal 6, numbers.uniq.size
    assert(numbers.all? { |n| n.between?(1, 60) })
  end

  test "mostra o histórico de cada dezena" do
    create_draw(1, [ 1, 2, 3, 4, 5, 6 ])
    create_draw(2, [ 1, 2, 3, 7, 8, 9 ])

    get random_draw_path(numbers: "01-02-03-04-05-60")

    assert_response :success
    assert_match(/Histórico de cada dezena/, response.body)
    assert_match(/nunca saiu/, response.body)             # dezena 60
    assert_match(/saiu no último concurso/, response.body) # dezenas 1, 2 e 3
    assert_match(/ainda não foi sorteada/, response.body)
    assert_match(/Maior acerto histórico/, response.body)
    assert_select "tbody tr", 6
  end

  test "avisa quando a combinação já foi sorteada" do
    create_draw(7, [ 1, 2, 3, 4, 5, 6 ])

    get random_draw_path(numbers: "06 05 04 03 02 01")

    assert_response :success
    assert_match(/já foi sorteada/, response.body)
    assert_match(/#7/, response.body)
  end

  test "sem concursos cadastrados orienta a importar" do
    get random_draw_path(numbers: "01-02-03-04-05-06")

    assert_response :success
    assert_match(/Ainda não há concursos/, response.body)
  end

  test "dezenas inválidas mostram aviso" do
    [ "01-01-02-03-04-05", "01-02-03-04-05", "01-02-03-04-05-61", "00-01-02-03-04-05", "abc" ].each do |value|
      get random_draw_path(numbers: value)

      assert_response :success
      assert_match(/seis dezenas distintas/, response.body, "esperava aviso para #{value.inspect}")
    end
  end
end
