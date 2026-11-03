module MegaSena
  class ProbabilityCalculator
    TOTAL_COMBINATIONS = 50_063_860

    def call
      {
        total_combinations: TOTAL_COMBINATIONS,
        simple_game_probability: Rational(1, TOTAL_COMBINATIONS),
        percentage: 100.0 / TOTAL_COMBINATIONS
      }
    end
  end
end