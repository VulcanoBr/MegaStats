class NumberAnalysesController < ApplicationController
  def index
    @period = params[:period].presence || "all"

    @frequencies =
      if @period == "all"
        MegaSena::NumberFrequency.new.call
      else
        result = MegaSena::RecentFrequency.new(period: @period).call
        result[:frequencies]
      end

    @frequencies = @frequencies.sort_by do |item|
      [-item[:count], item[:number]]
    end
  rescue ArgumentError
    redirect_to number_analyses_path(period: "all"),
                alert: "Período inválido."
  end
end