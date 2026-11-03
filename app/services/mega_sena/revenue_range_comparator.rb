
# frozen_string_literal: true

module MegaSena
  class RevenueRangeComparator
    RANKING_SIZE = 10

    def call
      ranges = RevenueRangeDefinitions.all.map do |definition|
        analyze_range(definition)
      end

      variations = calculate_variations(ranges)

      {
        generated_at: Time.current,
        ranges: ranges,
        total_draws_with_revenue: ranges.sum { |range| range[:total_draws] },
        total_numbers: 60,
        variations: variations,
        variation_rankings: {
          largest_increase: variations.sort_by do |item|
            [-item[:variation].to_f, item[:number]]
          end.first(RANKING_SIZE),

          largest_decrease: variations.sort_by do |item|
            [item[:variation].to_f, item[:number]]
          end.first(RANKING_SIZE)
        }
      }
    end

    private

    def analyze_range(definition)
      scope = apply_range(Draw.all, definition)
      total_draws = scope.count

      frequencies = MegaSena::NumberFrequency.new(scope: scope).call

      {
        key: definition[:key],
        name: definition[:name],
        minimum: definition[:minimum],
        maximum: definition[:maximum],
        total_draws: total_draws,
        frequencies: frequencies,
        rankings: build_rankings(frequencies, total_draws)
      }
    end

    def build_rankings(frequencies, total_draws)
      return { most_frequent: [], least_frequent: [] } if total_draws.zero?

      {
        most_frequent: frequencies.sort_by do |item|
          [-item[:percentage], item[:number]]
        end.first(RANKING_SIZE),

        least_frequent: frequencies.sort_by do |item|
          [item[:percentage], item[:number]]
        end.first(RANKING_SIZE)
      }
    end

    def calculate_variations(ranges)
      first_range = ranges.first
      last_range = ranges.last

      return [] unless first_range && last_range
      return [] if first_range[:total_draws].zero?
      return [] if last_range[:total_draws].zero?

      first_frequencies = index_frequencies(first_range[:frequencies])
      last_frequencies = index_frequencies(last_range[:frequencies])

      (1..60).map do |number|
        first_percentage = first_frequencies.fetch(number)[:percentage]
        last_percentage = last_frequencies.fetch(number)[:percentage]

        {
          number: number,
          first_range_percentage: first_percentage,
          last_range_percentage: last_percentage,
          variation: (last_percentage - first_percentage).round(2)
        }
      end
    end

    def index_frequencies(frequencies)
      frequencies.index_by { |item| item[:number] }
    end

    def apply_range(scope, definition)
      if definition[:minimum] && definition[:maximum]
        scope.where(
          "total_revenue > ? AND total_revenue <= ?",
          definition[:minimum],
          definition[:maximum]
        )
      elsif definition[:maximum]
        scope.where(
          "total_revenue <= ?",
          definition[:maximum]
        )
      else
        scope.where(
          "total_revenue > ?",
          definition[:minimum]
        )
      end
    end
  end
end
