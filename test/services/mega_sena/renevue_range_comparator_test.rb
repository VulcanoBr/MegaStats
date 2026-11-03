# frozen_string_literal: true

require "test_helper"

class MegaSena::RevenueRangeComparatorTest < ActiveSupport::TestCase
  MILLION = BigDecimal("1000000")

  test "classifies draws into the correct revenue ranges" do
    create_draw(1, 20 * MILLION)
    create_draw(2, 20 * MILLION + 1)
    create_draw(3, 50 * MILLION)
    create_draw(4, 50 * MILLION + 1)
    create_draw(5, 100 * MILLION)
    create_draw(6, 100 * MILLION + 1)
    create_draw(7, 200 * MILLION)
    create_draw(8, 200 * MILLION + 1)
    create_draw(9, 400 * MILLION)
    create_draw(10, 400 * MILLION + 1)

    result = MegaSena::RevenueRangeComparator.new.call

    ranges = result[:ranges].index_by { |range| range[:key] }

    assert_equal 1, ranges[:up_to_20_million][:total_draws]
    assert_equal 2, ranges[:from_20_to_50_million][:total_draws]
    assert_equal 2, ranges[:from_50_to_100_million][:total_draws]
    assert_equal 2, ranges[:from_100_to_200_million][:total_draws]
    assert_equal 2, ranges[:from_200_to_400_million][:total_draws]
    assert_equal 1, ranges[:above_400_million][:total_draws]

    assert_equal 10, result[:total_draws_with_revenue]
  end

  test "excludes draws without revenue" do
    create_draw(1, nil)
    create_draw(2, 10 * MILLION)

    result = MegaSena::RevenueRangeComparator.new.call

    assert_equal 1, result[:total_draws_with_revenue]
  end

  test "calculates frequency rankings for each range" do
    create_draw(1, 10 * MILLION)
    create_draw(2, 30 * MILLION)
    create_draw(3, 60 * MILLION)
    create_draw(4, 150 * MILLION)
    create_draw(5, 300 * MILLION)
    create_draw(6, 500 * MILLION)

    result = MegaSena::RevenueRangeComparator.new.call

    result[:ranges].each do |range|
      assert_equal 10, range[:rankings][:most_frequent].size
      assert_equal 10, range[:rankings][:least_frequent].size

      assert_equal(
        range[:rankings][:most_frequent].sort_by do |item|
          [-item[:percentage], item[:number]]
        end,
        range[:rankings][:most_frequent]
      )

      assert_equal(
        range[:rankings][:least_frequent].sort_by do |item|
          [item[:percentage], item[:number]]
        end,
        range[:rankings][:least_frequent]
      )
    end
  end

  test "calculates variations between the first and last ranges" do
    create_draw(1, 10 * MILLION)
    create_draw(2, 500 * MILLION)

    result = MegaSena::RevenueRangeComparator.new.call

    assert_equal 60, result[:variations].size

    variation = result[:variations].find do |item|
      item[:number] == 1
    end

    assert_equal 100.0, variation[:first_range_percentage]
    assert_equal 100.0, variation[:last_range_percentage]
    assert_equal 0.0, variation[:variation]

    assert_equal 10, result[:variation_rankings][:largest_increase].size
    assert_equal 10, result[:variation_rankings][:largest_decrease].size
  end

  test "does not calculate variations when an extreme range is empty" do
    create_draw(1, 10 * MILLION)

    result = MegaSena::RevenueRangeComparator.new.call

    assert_empty result[:variations]
    assert_empty result[:variation_rankings][:largest_increase]
    assert_empty result[:variation_rankings][:largest_decrease]
  end


  private

  def create_draw(contest_number, revenue)
    Draw.create!(
      contest_number: contest_number,
      draw_date: Date.new(2026, 1, contest_number),
      number_1: 1,
      number_2: 2,
      number_3: 3,
      number_4: 4,
      number_5: 5,
      number_6: 6,
      total_revenue: revenue
    )
  end
end