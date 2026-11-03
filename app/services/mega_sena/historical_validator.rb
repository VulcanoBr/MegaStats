require "set"

module MegaSena
  class HistoricalValidator

    NUMBER_COLUMNS = (1..6).map { |n| :"number_#{n}" }.freeze

    MONEY_COLUMNS = %i[
      prize_sena
      prize_quina
      prize_quadra
      accumulated_sena
      total_revenue
      estimated_prize
      special_draw_accumulated
    ].freeze

    def call
      draws = Draw.order(:contest_number).to_a

      report = {
        checked_at: Time.current,
        total_draws: draws.size,
        errors: [],
        warnings: [],
        statistics: {}
      }

      validate_numbers(draws, report)
      validate_dates(draws, report)
      validate_money(draws, report)
      validate_sequence(draws, report)

      report[:statistics] = {
        first_contest: draws.first&.contest_number,
        last_contest: draws.last&.contest_number,
        first_date: draws.first&.draw_date,
        last_date: draws.last&.draw_date,
        distinct_contests: draws.map(&:contest_number).uniq.size
      }

      report[:status] =
        if report[:errors].any?
          "failed"
        elsif report[:warnings].any?
          "warning"
        else
          "passed"
        end

      report
    end

    private

    def validate_numbers(draws, report)
      draws.each do |draw|
        numbers = NUMBER_COLUMNS.map do |column|
          draw.public_send(column)
        end

        unless numbers.all? { |number| number.is_a?(Integer) && (1..60).cover?(number) }
          report[:errors] << issue(
            draw,
            "invalid_numbers",
            "Os números devem ser inteiros entre 1 e 60."
          )
          next
        end

        unless numbers.uniq.size == 6
          report[:errors] << issue(
            draw,
            "duplicate_numbers",
            "O concurso contém números repetidos."
          )
        end
      end
    end

    def validate_dates(draws, report)
      draws.each do |draw|
        next if draw.draw_date.present?

        report[:errors] << issue(
          draw,
          "missing_date",
          "A data do concurso está vazia."
        )
      end

      draws.each_cons(2) do |previous, current|
        next unless previous.draw_date && current.draw_date
        next if current.draw_date >= previous.draw_date

        report[:warnings] << issue(
          current,
          "date_order",
          "A data é anterior à data do concurso precedente."
        )
      end
    end

    def validate_money(draws, report)
      draws.each do |draw|
        MONEY_COLUMNS.each do |column|
          value = draw.public_send(column)
          next if value.nil? || value >= 0

          report[:warnings] << issue(
            draw,
            "negative_amount",
            "#{column} contém um valor negativo."
          )
        end
      end
    end

    def validate_sequence(draws, report)
      numbers = draws.map(&:contest_number)

      return if numbers.empty?

      duplicates = numbers.tally.select do |_number, count|
        count > 1
      end

      duplicates.each_key do |number|
        report[:errors] << {
          contest_number: number,
          code: "duplicate_contest",
          message: "Número de concurso duplicado."
        }
      end

      existing_numbers = numbers.to_set

      (numbers.min...numbers.max).each do |number|
        next if existing_numbers.include?(number)

        report[:warnings] << {
          contest_number: number,
          code: "contest_gap",
          message: "Concurso ausente no histórico importado."
        }
      end
    end

    def issue(draw, code, message)
      {
        contest_number: draw.contest_number,
        code: code,
        message: message
      }
    end
  end
end