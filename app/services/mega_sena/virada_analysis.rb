module MegaSena
  # Análise dos concursos da Mega da Virada.
  #
  # A planilha oficial da Caixa NÃO traz uma coluna que identifique a Virada, então ela é reconhecida pela data:
  # sorteio em 31/12 (ou em 01/01, caso do concurso 2955, que na planilha aparece datado de 01/01/2026),
  # a partir da primeira edição oficial (31/12/2009, concurso 1140).
  #
  # Conferência feita na planilha de 01/11/2026: a regra encontra 17 concursos (1140, 1245, 1350, 1455, 1560,
  # 1665, 1775, 1890, 2000, 2110, 2220, 2330, 2440, 2550, 2670, 2810 e 2955) e todos tiveram ganhadores da Sena
  # (a Virada não acumula). O concurso 1035, de 31/12/2008, fica de fora: não teve ganhador e acumulou.
  class ViradaAnalysis
    NUMBER_COLUMNS = %i[number_1 number_2 number_3 number_4 number_5 number_6].freeze

    FIRST_EDITION_DATE = Date.new(2009, 12, 31)

    # Ajustes manuais, caso a Caixa registre uma edição fora da regra de datas (ou se queira ignorar uma).
    EXTRA_CONTESTS = [].freeze
    EXCLUDED_CONTESTS = [].freeze

    # edition: posição entre as Viradas (1 = primeira); year: ano da Virada (o sorteio de 01/01/2026 é a Virada 2025)
    Edition = Data.define(:edition, :year, :contest_number, :draw_date, :numbers, :winners_sena, :prize_sena)

    NumberStat = Data.define(
      :number, :times_drawn, :percent_of_editions, :last_edition, :last_contest, :last_date, :editions_since_last
    ) do
      def never_drawn? = times_drawn.zero?
      def drawn_in_latest? = editions_since_last.zero?
    end

    Result = Data.define(:editions, :number_stats) do
      def total_editions = editions.size
      def latest = editions.last
      def never_drawn_numbers = number_stats.select(&:never_drawn?).map(&:number)
      def distinct_numbers_drawn = number_stats.count { |stat| !stat.never_drawn? }
    end

    # Data de sorteio compatível com a Virada (31/12 ou 01/01).
    def self.special_date?(date)
      (date.month == 12 && date.day == 31) || (date.month == 1 && date.day == 1)
    end

    def call
      rows = Draw.where(draw_date: FIRST_EDITION_DATE..)
                 .order(:contest_number)
                 .pluck(:contest_number, :draw_date, :winners_sena, :prize_sena, *NUMBER_COLUMNS)

      selected = rows.select do |contest, date, *|
        next false if EXCLUDED_CONTESTS.include?(contest)

        EXTRA_CONTESTS.include?(contest) || self.class.special_date?(date)
      end

      editions = selected.each_with_index.map do |(contest, date, winners, prize, *numbers), index|
        Edition.new(
          edition: index + 1,
          year: date.month == 1 ? date.year - 1 : date.year,
          contest_number: contest,
          draw_date: date,
          numbers: numbers.sort,
          winners_sena: winners,
          prize_sena: prize
        )
      end

      Result.new(editions: editions, number_stats: build_stats(editions))
    end

    private

    def build_stats(editions)
      total = editions.size
      counts = Hash.new(0)
      last_edition = {}

      editions.each do |edition|
        edition.numbers.each do |number|
          counts[number] += 1
          last_edition[number] = edition
        end
      end

      (1..60).map do |number|
        last = last_edition[number]
        NumberStat.new(
          number: number,
          times_drawn: counts[number],
          percent_of_editions: total.zero? ? 0.0 : counts[number] * 100.0 / total,
          last_edition: last&.edition,
          last_contest: last&.contest_number,
          last_date: last&.draw_date,
          # nunca saiu: conta todas as edições; saiu na última edição: 0
          editions_since_last: last ? total - last.edition : total
        )
      end
    end
  end
end
