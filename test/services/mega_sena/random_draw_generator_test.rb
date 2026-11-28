require "test_helper"

class MegaSena::RandomDrawGeneratorTest < ActiveSupport::TestCase
  test "sorteia seis dezenas distintas entre 1 e 60, em ordem crescente" do
    200.times do
      numbers = MegaSena::RandomDrawGenerator.call

      assert_equal 6, numbers.size
      assert_equal 6, numbers.uniq.size
      assert(numbers.all? { |n| n.between?(1, 60) })
      assert_equal numbers.sort, numbers
    end
  end

  test "é reproduzível com a mesma semente" do
    first = MegaSena::RandomDrawGenerator.call(random: Random.new(42))
    second = MegaSena::RandomDrawGenerator.call(random: Random.new(42))

    assert_equal first, second
  end

  test "ao longo de muitos sorteios todas as dezenas aparecem" do
    random = Random.new(1)
    seen = 300.times.flat_map { MegaSena::RandomDrawGenerator.call(random: random) }.uniq

    assert_equal (1..60).to_a, seen.sort
  end
end
