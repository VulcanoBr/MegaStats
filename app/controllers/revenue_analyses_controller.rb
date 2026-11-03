
# frozen_string_literal: true

class RevenueAnalysesController < ApplicationController
  TABS = %w[overview ranges rankings custom].freeze

  def index
    @minimum = params[:minimum]
    @maximum = params[:maximum]

    @active_tab = selected_tab

    @range_comparison = MegaSena::RevenueRangeComparator.new.call

    @search_performed =
      @active_tab == "custom" &&
      (params.key?(:minimum) || params.key?(:maximum))

    @total_draws = 0
    @frequencies = []

    return unless @search_performed

    if @minimum.blank? && @maximum.blank?
      flash.now[:alert] =
        "Informe pelo menos um limite de arrecadação."
      return
    end

    result = MegaSena::RevenueAnalysis.new(
      minimum: @minimum,
      maximum: @maximum
    ).call

    @total_draws = result[:total_draws]

    @frequencies = result[:frequencies].sort_by do |item|
      [-item[:count], item[:number]]
    end

  rescue ArgumentError => e
    flash.now[:alert] = e.message
    @total_draws = 0
    @frequencies = []
  end

  private

  def selected_tab
    requested_tab = params[:tab].presence

    return requested_tab if TABS.include?(requested_tab)

    if params.key?(:minimum) || params.key?(:maximum)
      "custom"
    else
      "overview"
    end
  end
end
