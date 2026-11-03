module MegaSena
  class NumberFrequency
    NUMBER_COLUMNS = (1..6).map { |n| :"number_#{n}" }.freeze

    def initialize(scope: Draw.all)
      @scope = scope
    end

    def call
      draws = @scope
        .reorder(:contest_number)
        .pluck(*NUMBER_COLUMNS)

      counts = Hash.new(0)

      draws.each do |numbers|
        numbers.each do |number|
          counts[number] += 1
        end
      end

      total_draws = draws.size

      (1..60).map do |number|
        {
          number: number,
          count: counts[number],
          percentage: percentage(counts[number], total_draws),
          total_draws: total_draws
        }
      end
    end

    private

    def percentage(count, total)
      return 0.0 if total.zero?

      (count.to_f * 100 / total).round(2)
    end
  end
end