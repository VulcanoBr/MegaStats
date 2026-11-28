module MegaSena
  # Sorteia 6 dezenas distintas entre 01 e 60 (amostragem sem reposição), em ordem crescente.
  class RandomDrawGenerator
    def self.call(random: Random.new)
      (1..60).to_a.sample(6, random: random).sort
    end
  end
end
