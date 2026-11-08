
class WinnerRangeAnalysesController < ApplicationController
  def index
    @minimum_winners = params[:minimum_winners]
    @maximum_winners = params[:maximum_winners]

    return if @minimum_winners.blank? || @maximum_winners.blank?

    @analysis = MegaSena::Statistics::WinnerRangeAnalysis.new(
      minimum_winners: @minimum_winners,
      maximum_winners: @maximum_winners
    ).call
  rescue ArgumentError => e
    @analysis_error = e.message
  end
end
