
# frozen_string_literal: true

require "test_helper"

class CombinationAnalysesControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_draw(1, [1, 2, 3, 4, 5, 6])
    create_draw(2, [1, 2, 3, 7, 8, 9])
    create_draw(3, [1, 4, 7, 10, 11, 12])
  end

  test "exibe a página de consulta de combinações" do
    get combination_analyses_path

    assert_response :success
    assert_select "h1", "Consultar combinação"
    assert_select "form[action='#{combination_analyses_path}'][method='post']"
    assert_select "input[name='numbers[]']", 6
    assert_select "input[type='submit'][value='Consultar combinação']"
  end

  test "consulta uma combinação existente no histórico" do
    post combination_analyses_path, params: {
      numbers: [1, 2, 3, 4, 5, 6]
    }

    assert_response :success

    assert_select "h2", text: "Resultado da consulta"

    assert_includes response.body, "01 - 02 - 03 - 04 - 05 - 06"

    assert_includes response.body, "1 em 50.063.860"

    assert_includes response.body, "Estatísticas individuais das dezenas"

    assert_select "tbody tr", 6
  end

  test "informa quando a combinação não existe no histórico" do
    post combination_analyses_path,
         params: {
           numbers: [13, 14, 15, 16, 17, 18]
         }

    assert_response :success

    assert_select "h2", "Resultado da consulta"

    assert_select "p",
                  text: "Essa combinação não foi encontrada no histórico importado."
  end

  test "apresenta mensagem quando a combinação possui números repetidos" do
    post combination_analyses_path,
         params: {
           numbers: [1, 2, 3, 4, 5, 5]
         }

    assert_response :unprocessable_entity

    assert_select "div",
                  text: "Informe exatamente seis números distintos entre 1 e 60."
  end

  test "apresenta mensagem quando a combinação possui menos de seis números" do
    post combination_analyses_path,
         params: {
           numbers: [1, 2, 3, 4, 5]
         }

    assert_response :unprocessable_entity

    assert_select "div",
                  text: "Informe exatamente seis números distintos entre 1 e 60."
  end

  test "gera combinações inéditas" do
    get unseen_combination_analyses_path

    assert_response :success
    assert_select "h1", "Cinco combinações inéditas"
    assert_select "article", 5
  end

  test "apresenta combinações menos frequentes" do
    get least_frequent_combination_analyses_path

    assert_response :success
    assert_select "h1", "Combinações menos frequentes"
    assert_select "article", 3
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
