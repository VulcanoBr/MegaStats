require "test_helper"

class MegaSena::NumberFrequencyTest < ActiveSupport::TestCase
  test "retorna os 60 números no histórico vazio" do
    result = MegaSena::NumberFrequency.new.call

    assert_equal 60, result.size
    assert_equal (1..60).to_a, result.map { |item| item[:number] }
    assert result.all? { |item| item[:count].zero? }
  end

  test "contabiliza as ocorrências dos números" do
    Draw.create!(
      contest_number: 900_001,
      draw_date: Date.new(2026, 1, 1),
      number_1: 1,
      number_2: 2,
      number_3: 3,
      number_4: 4,
      number_5: 5,
      number_6: 6
    )

    result = MegaSena::NumberFrequency.new.call
    number_one = result.find { |item| item[:number] == 1 }

    assert_equal 1, number_one[:count]
    assert_equal 100.0, number_one[:percentage]
  end
end