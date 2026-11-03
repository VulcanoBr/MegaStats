# frozen_string_literal: true

module MegaSena
  class RevenueRangeDefinitions
    MILLION = BigDecimal("1000000")

    RANGES = [
      {
        key: :up_to_20_million,
        name: "Até R$ 20 milhões",
        maximum: 20 * MILLION
      },
      {
        key: :from_20_to_50_million,
        name: "Acima de R$ 20 até R$ 50 milhões",
        minimum: 20 * MILLION,
        maximum: 50 * MILLION
      },
      {
        key: :from_50_to_100_million,
        name: "Acima de R$ 50 até R$ 100 milhões",
        minimum: 50 * MILLION,
        maximum: 100 * MILLION
      },
      {
        key: :from_100_to_200_million,
        name: "Acima de R$ 100 até R$ 200 milhões",
        minimum: 100 * MILLION,
        maximum: 200 * MILLION
      },
      {
        key: :from_200_to_400_million,
        name: "Acima de R$ 200 até R$ 400 milhões",
        minimum: 200 * MILLION,
        maximum: 400 * MILLION
      },
      {
        key: :above_400_million,
        name: "Acima de R$ 400 milhões",
        minimum: 400 * MILLION
      }
    ].map(&:freeze).freeze

    def self.all
      RANGES
    end
  end
end