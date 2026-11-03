
require "test_helper"

module MegaSena
  module Statistics
    class DelayAnalyzerTest < ActiveSupport::TestCase
      test "retorna informações para as sessenta dezenas" do
        create_draw(1, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal 60, result[:data].size
        assert_equal (1..60).to_a,
                     result[:data].map { |item| item[:number] }
      end

      test "calcula a quantidade de aparições de uma dezena" do
        create_draw(1, [1, 2, 3, 4, 5, 15])
        create_draw(2, [1, 2, 3, 4, 5, 6])
        create_draw(3, [1, 2, 3, 4, 5, 15])

        result = analyze

        assert_equal 2, number_for(result, 15)[:occurrence_count]
      end

      test "calcula corretamente o atraso atual" do
        create_draw(1, [1, 2, 3, 4, 5, 15])
        create_draw(2, [1, 2, 3, 4, 5, 6])
        create_draw(3, [1, 2, 3, 4, 5, 6])
        create_draw(4, [1, 2, 3, 4, 5, 15])
        create_draw(5, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal 1, number_for(result, 15)[:current_delay]
      end

      test "retorna atraso atual zero quando a dezena saiu no último concurso" do
        create_draw(1, [1, 2, 3, 4, 5, 15])
        create_draw(2, [1, 2, 3, 4, 5, 6])

        result = analyze

        assert_equal 1, number_for(result, 15)[:current_delay]
        assert_equal 0, number_for(result, 6)[:current_delay]
      end

      test "calcula os intervalos entre aparições" do
        appearances = [1, 3, 4, 8, 10]

        (1..10).each do |contest|
          numbers = appearances.include?(contest) ?
            [1, 2, 3, 4, 5, 15] :
            [1, 2, 3, 4, 5, 6]

          create_draw(contest, numbers)
        end

        result = analyze

        assert_equal [2, 1, 4, 2],
                     number_for(result, 15)[:intervals_between_appearances]
      end

      test "calcula os atrasos históricos entre aparições" do
        appearances = [1, 3, 4, 8, 10]

        (1..10).each do |contest|
          numbers = appearances.include?(contest) ?
            [1, 2, 3, 4, 5, 15] :
            [1, 2, 3, 4, 5, 6]

          create_draw(contest, numbers)
        end

        result = analyze

        assert_equal [1, 0, 3, 1],
                     number_for(result, 15)[:historical_delays]
      end

      test "calcula o maior atraso histórico" do
        appearances = [1, 3, 4, 8, 10]

        (1..10).each do |contest|
          numbers = appearances.include?(contest) ?
            [1, 2, 3, 4, 5, 15] :
            [1, 2, 3, 4, 5, 6]

          create_draw(contest, numbers)
        end

        result = analyze

        assert_equal 3,
                     number_for(result, 15)[:maximum_historical_delay]
      end

      test "calcula o atraso histórico médio" do
        appearances = [1, 3, 4, 8, 10]

        (1..10).each do |contest|
          numbers = appearances.include?(contest) ?
            [1, 2, 3, 4, 5, 15] :
            [1, 2, 3, 4, 5, 6]

          create_draw(contest, numbers)
        end

        result = analyze

        assert_in_delta 1.25,
                        number_for(result, 15)[:average_historical_delay],
                        0.001
      end

      test "não considera o atraso atual como atraso histórico" do
        create_draw(1, [1, 2, 3, 4, 5, 15])
        create_draw(2, [1, 2, 3, 4, 5, 6])
        create_draw(3, [1, 2, 3, 4, 5, 15])
        create_draw(4, [1, 2, 3, 4, 5, 6])
        create_draw(5, [1, 2, 3, 4, 5, 6])
        create_draw(6, [1, 2, 3, 4, 5, 6])

        result = analyze
        item = number_for(result, 15)

        assert_equal 3, item[:current_delay]
        assert_equal [1], item[:historical_delays]
        assert_equal 1, item[:maximum_historical_delay]
      end

      test "trata uma dezena que nunca apareceu" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [7, 8, 9, 10, 11, 12])

        result = analyze
        item = number_for(result, 60)

        assert_equal 0, item[:occurrence_count]
        assert_equal 2, item[:current_delay]
        assert_empty item[:intervals_between_appearances]
        assert_empty item[:historical_delays]
        assert_nil item[:maximum_historical_delay]
        assert_nil item[:average_historical_delay]
        assert_nil item[:first_appearance_contest]
        assert_nil item[:last_appearance_contest]
      end

      test "trata uma dezena que apareceu apenas uma vez" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 4, 5, 15])
        create_draw(3, [1, 2, 3, 4, 5, 6])

        result = analyze
        item = number_for(result, 15)

        assert_equal 1, item[:occurrence_count]
        assert_equal 1, item[:current_delay]
        assert_empty item[:historical_delays]
        assert_nil item[:maximum_historical_delay]
        assert_nil item[:average_historical_delay]
        assert_nil item[:average_interval_between_appearances]
        
      end

      test "calcula os indicadores gerais do histórico" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 4, 5, 15])

        result = analyze
        metrics = result[:metrics]

        assert_equal 60, metrics[:total_numbers]
        assert_equal 12, metrics[:total_occurrences]
        assert_equal 5, metrics[:total_historical_intervals]
        assert_equal 5, metrics[:total_historical_delays]
        assert_equal 53, metrics[:numbers_never_drawn]
        assert_equal 2, metrics[:numbers_drawn_once]
        assert_equal 5, metrics[:numbers_drawn_more_than_once] 
        assert_in_delta 1.0,
                metrics[:average_interval_between_appearances],
                0.001         
      end

      test "ordena as dezenas pelo maior atraso atual" do
        create_draw(1, [1, 2, 3, 4, 5, 6])
        create_draw(2, [1, 2, 3, 4, 5, 15])
        create_draw(3, [1, 2, 3, 4, 5, 15])

        result = analyze

        ranking = result[:rankings][:most_delayed_current]

        assert_equal 7, ranking.first[:number]
        assert_equal 3, ranking.first[:current_delay]
      end

      test "ordena as dezenas pelo maior atraso histórico" do
        appearances = [1, 3, 4, 8, 10]

        (1..10).each do |contest|
          numbers = appearances.include?(contest) ?
            [1, 2, 3, 4, 5, 15] :
            [1, 2, 3, 4, 5, 6]

          create_draw(contest, numbers)
        end

        result = analyze

        ranking = result[:rankings][:largest_historical_delay]

        assert_equal 15, ranking.first[:number]
        assert_equal 3, ranking.first[:maximum_historical_delay]
      end

      test "trata corretamente um dataset vazio" do
        dataset = Dataset.new(relation: Draw.none)

        result = DelayAnalyzer.new(dataset: dataset).call

        assert_equal 0, result[:total_draws]
        assert_equal 60, result[:data].size
        assert_equal 0, result[:metrics][:total_occurrences]
        assert_equal 60, result[:metrics][:numbers_never_drawn]
        assert_nil result[:metrics][:average_current_delay]
        assert_nil result[:metrics][:maximum_current_delay]

        assert(
          result[:data].all? do |item|
            item[:current_delay].nil? &&
              item[:occurrence_count].zero? &&
              item[:intervals_between_appearances].empty? &&
              item[:historical_delays].empty?
          end
        )

        assert_empty result[:rankings][:largest_historical_delay]
      end

      test "calcula o intervalo médio entre aparições de cada dezena" do
        appearances = [1, 3, 4, 8, 10]

        (1..10).each do |contest|
          numbers = appearances.include?(contest) ?
            [1, 2, 3, 4, 5, 15] :
            [1, 2, 3, 4, 5, 6]

          create_draw(contest, numbers)
        end

        result = analyze
        item = number_for(result, 15)

        assert_equal [2, 1, 4, 2],
                    item[:intervals_between_appearances]

        assert_in_delta 2.25,
                        item[:average_interval_between_appearances],
                        0.001
      end

      private

      def analyze
        dataset = Dataset.new

        DelayAnalyzer.new(dataset: dataset).call
      end

      def number_for(result, number)
        result[:data].find { |item| item[:number] == number }
      end

      def create_draw(contest_number, numbers)
        Draw.create!(
          contest_number: contest_number,
          draw_date: Date.new(2026, 1, contest_number),
          number_1: numbers[0],
          number_2: numbers[1],
          number_3: numbers[2],
          number_4: numbers[3],
          number_5: numbers[4],
          number_6: numbers[5]
        )
      end
    end
  end
end
