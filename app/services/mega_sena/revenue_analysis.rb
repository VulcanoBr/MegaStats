module MegaSena
  class RevenueAnalysis
    NUMBER_COLUMNS = (1..6).map { |n| :"number_#{n}" }.freeze

    def initialize(minimum: nil, maximum: nil)
      @minimum = parse_amount(minimum)
      @maximum = parse_amount(maximum)

      if @minimum && @maximum && @minimum > @maximum
        raise ArgumentError,
              "O valor mínimo não pode superar o máximo."
      end
    end

    def call
      scope = Draw.all

      scope = scope.where("total_revenue >= ?", @minimum) if @minimum
      scope = scope.where("total_revenue <= ?", @maximum) if @maximum

      {
        minimum: @minimum,
        maximum: @maximum,
        total_draws: scope.count,
        frequencies: NumberFrequency.new(scope: scope).call
      }
    end

    private

    def parse_amount(value)
      return nil if value.nil? || value.to_s.strip.empty?

      amount = begin
        BigDecimal(value.to_s)
      rescue ArgumentError
        raise ArgumentError, "Valor de arrecadação inválido: #{value.inspect}"
      end

      if amount.negative?
        raise ArgumentError, "A arrecadação não pode ser negativa."
      end

      amount
    end

  end
end