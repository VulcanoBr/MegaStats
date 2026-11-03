require "set"

module MegaSena
  class UnseenCombinationGenerator
    def initialize(quantity: 5)
      @quantity = Integer(quantity)

      unless (1..100).cover?(@quantity)
        raise ArgumentError, "A quantidade deve estar entre 1 e 100."
      end
    end

    def call
      existing = Set.new

      Draw.find_each do |draw|
        existing.add(draw_numbers(draw))
      end

      generated = Set.new
      attempts = 0
      max_attempts = 100_000

      while generated.size < @quantity && attempts < max_attempts
        attempts += 1

        combination = (1..60).to_a.sample(6).sort

        next if existing.include?(combination)
        next if generated.include?(combination)

        generated.add(combination)
      end

      if generated.size < @quantity
        raise "Não foi possível gerar a quantidade solicitada."
      end

      generated.to_a.sort
    end

    private

    def draw_numbers(draw)
      (1..6).map do |position|
        draw.public_send(:"number_#{position}")
      end.sort
    end
  end
end