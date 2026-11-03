
# frozen_string_literal: true

require "test_helper"

class StatisticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_draw(1, [1, 2, 3, 4, 5, 6])
    create_draw(2, [1, 2, 3, 7, 8, 9])
    create_draw(3, [1, 4, 7, 10, 11, 12])
  end

  test "exibe a visão geral das estatísticas" do
    get statistics_path

    assert_response :success
    assert_select "h1", "Visão geral"
    assert_select "nav[aria-label='Análises estatísticas']"
  end

  test "renderiza a análise de frequência" do
    get statistics_path(analysis: "frequency")

    assert_response :success
    assert_select "h1", "Frequência das dezenas"
    # assert_select "table", false
  end

  test "renderiza a análise de paridade" do
    get statistics_path(analysis: "parity")

    assert_response :success
    assert_select "h1", "Paridade"
  end

  test "renderiza a análise de soma" do
    get statistics_path(analysis: "sum")

    assert_response :success
    assert_select "h1", "Soma das dezenas"
  end

  test "renderiza a análise de sequências" do
    get statistics_path(analysis: "sequence")

    assert_response :success
    assert_select "h1", "Sequências e intervalos"
  end

  test "renderiza a análise de atrasos" do
    get statistics_path(analysis: "delay")

    assert_response :success
    assert_select "h1", "Atrasos das dezenas"
  end

  test "renderiza a análise combinatória" do
    get statistics_path(analysis: "combination")

    assert_response :success
    assert_select "h1", "Análise combinatória"
  end

  test "redireciona quando a análise não existe" do
    get statistics_path(analysis: "invalid")

    assert_redirected_to statistics_path
  end

  test "a ação run redireciona para a análise selecionada" do
    post run_statistics_path, params: { analysis: "frequency" }

    assert_response :see_other
    assert_redirected_to statistics_path(analysis: "frequency")
  end

  test "rejeita execução de uma análise inválida" do
    post run_statistics_path, params: { analysis: "invalid" }

    assert_redirected_to statistics_path
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
