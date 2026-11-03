module MegaSena
  class RecentFrequency
    ALLOWED_PERIODS = [10, 20, 30].freeze

    def initialize(period:)
      @period = Integer(period)
    end

    def call
      unless ALLOWED_PERIODS.include?(@period)
        raise ArgumentError,
              "Período inválido. Utilize 10, 20 ou 30 concursos."
      end

      scope = Draw.order(contest_number: :desc).limit(@period)

      {
        period: @period,
        available_draws: scope.count,
        frequencies: NumberFrequency.new(scope: scope).call
      }
    end
  end
end