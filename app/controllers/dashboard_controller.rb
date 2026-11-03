class DashboardController < ApplicationController
  def index
    @total_draws = Draw.count
    @first_draw = Draw.order(:contest_number).first
    @last_draw = Draw.order(:contest_number).last

    @frequencies = MegaSena::NumberFrequency.new.call
      .sort_by { |item| [-item[:count], item[:number]] }

    @top_numbers = @frequencies.first(10)
    @least_numbers = @frequencies.last(10)
  end
end