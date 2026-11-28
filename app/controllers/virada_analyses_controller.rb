class ViradaAnalysesController < ApplicationController
  SORTS = %w[number times delay].freeze

  def index
    @result = MegaSena::ViradaAnalysis.new.call
    @sort = SORTS.include?(params[:sort]) ? params[:sort] : "number"

    @stats =
      case @sort
      when "times" then @result.number_stats.sort_by { |stat| [ -stat.times_drawn, stat.number ] }
      when "delay" then @result.number_stats.sort_by { |stat| [ -stat.editions_since_last, stat.number ] }
      else @result.number_stats
      end
  end
end
