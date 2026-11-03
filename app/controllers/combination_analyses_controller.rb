
# frozen_string_literal: true

class CombinationAnalysesController < ApplicationController
  def index
    @numbers = Array.new(6)
  end

  def create
    @numbers = Array(params[:numbers]).reject(&:blank?)

    @result = MegaSena::CombinationAnalyzer.new(
      numbers: @numbers
    ).call

    render :index
  rescue ArgumentError => e
    @numbers ||= Array.new(6)
    flash.now[:alert] = e.message

    render :index, status: :unprocessable_entity
  end

  def unseen
    @combinations =
      MegaSena::UnseenCombinationGenerator.new(quantity: 5).call
  end

  def least_frequent
    @combinations =
      MegaSena::LeastFrequentGenerator.new(quantity: 5).call
  end
end
