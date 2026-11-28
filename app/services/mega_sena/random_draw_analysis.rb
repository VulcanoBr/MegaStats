module MegaSena
  # Cruza seis dezenas com todo o histórico de concursos:
  # - quantas vezes cada dezena já saiu até o último concurso cadastrado;
  # - há quantos concursos cada dezena não sai (a partir da última aparição);
  # - se a combinação das seis dezenas já foi sorteada e, se não, qual foi o maior acerto histórico.
  class RandomDrawAnalysis
    NUMBER_COLUMNS = %i[number_1 number_2 number_3 number_4 number_5 number_6].freeze

    NumberStat = Data.define(
      :number, :times_drawn, :percent_of_draws, :last_contest, :last_date, :draws_since_last, :average_gap
    ) do
      def never_drawn? = times_drawn.zero?
      def drawn_in_latest? = draws_since_last == 0
    end

    # hits: dezenas escolhidas que saíram naquele concurso; numbers: as seis dezenas do concurso
    Match = Data.define(:contest_number, :draw_date, :numbers, :hits)

    Result = Data.define(
      :numbers, :total_draws, :latest_contest, :latest_date,
      :number_stats, :combination_matches, :best_hits, :best_matches
    ) do
      def already_drawn? = combination_matches.any?
    end

    def initialize(numbers)
      @numbers = numbers.map(&:to_i).sort
    end

    def call
      rows = Draw.order(:contest_number).pluck(:contest_number, :draw_date, *NUMBER_COLUMNS)

      counts = Hash.new(0)
      first_seen = {}
      last_seen = {}
      last_date = {}
      combination_matches = []
      best_hits = 0
      best_matches = []

      rows.each do |contest, date, *drawn|
        hits = drawn & @numbers
        next if hits.empty?

        hits.each do |number|
          counts[number] += 1
          first_seen[number] ||= contest
          last_seen[number] = contest
          last_date[number] = date
        end

        match = Match.new(contest_number: contest, draw_date: date, numbers: drawn.sort, hits: hits.sort)
        combination_matches << match if hits.size == 6

        if hits.size > best_hits
          best_hits = hits.size
          best_matches = [ match ]
        elsif hits.size == best_hits
          best_matches << match
        end
      end

      latest = rows.last
      latest_contest = latest&.first
      total = rows.size

      Result.new(
        numbers: @numbers,
        total_draws: total,
        latest_contest: latest_contest,
        latest_date: latest&.second,
        number_stats: @numbers.map do |number|
          times = counts[number]
          NumberStat.new(
            number: number,
            times_drawn: times,
            percent_of_draws: total.zero? ? 0.0 : times * 100.0 / total,
            last_contest: last_seen[number],
            last_date: last_date[number],
            draws_since_last: last_seen[number] && latest_contest ? latest_contest - last_seen[number] : nil,
            average_gap: times > 1 ? (last_seen[number] - first_seen[number]).to_f / (times - 1) : nil
          )
        end,
        combination_matches: combination_matches,
        best_hits: best_hits,
        best_matches: best_matches
      )
    end
  end
end
