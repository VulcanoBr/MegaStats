module MegaSena
  class LeastFrequentGenerator
    def initialize(quantity: 5)
      @quantity = Integer(quantity)

      unless (1..100).cover?(@quantity)
        raise ArgumentError, "A quantidade deve estar entre 1 e 100."
      end
    end

    def call
      counts = Hash.new(0)

      Draw.find_each do |draw|
        numbers = (1..6).map do |position|
          draw.public_send(:"number_#{position}")
        end.sort

        counts[numbers] += 1
      end

      counts.sort_by do |numbers, count|
        [count, numbers]
      end.first(@quantity).map do |numbers, count|
        {
          numbers: numbers,
          historical_occurrences: count
        }
      end
    end
  end
end