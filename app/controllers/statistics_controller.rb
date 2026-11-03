
# frozen_string_literal: true

class StatisticsController < ApplicationController
  ANALYSES = {
    "frequency" => {
      title: "Frequência das dezenas",
      description: "Analisa a frequência histórica de ocorrência de cada dezena."
    },
    "parity" => {
      title: "Paridade",
      description: "Analisa a distribuição de dezenas pares e ímpares."
    },
    "sum" => {
      title: "Soma das dezenas",
      description: "Analisa a distribuição estatística da soma das seis dezenas."
    },
    "sequence" => {
      title: "Sequências e intervalos",
      description: "Analisa sequências consecutivas e intervalos entre dezenas."
    },
    "delay" => {
      title: "Atrasos das dezenas",
      description: "Analisa os atrasos atuais e históricos das dezenas."
    },
    "combination" => {
      title: "Análise combinatória",
      description: "Analisa pares, trincas, combinações e repetições entre concursos."
    }
  }.freeze

  def show
    @selected_analysis = params[:analysis].presence || "overview"

    unless @selected_analysis == "overview" || ANALYSES.key?(@selected_analysis)
      redirect_to statistics_path, alert: "Análise estatística inválida."
      return
    end

    @analysis_options = ANALYSES

    @page_title =
      if @selected_analysis == "overview"
        "Visão geral"
      else
        ANALYSES.dig(@selected_analysis, :title)
      end

    @analysis_description =
      if @selected_analysis == "overview"
        "Indicadores gerais e acompanhamento do histórico da Mega-Sena."
      else
        ANALYSES.dig(@selected_analysis, :description)
      end

    @dataset = MegaSena::Statistics::Dataset.new
    @total_draws = @dataset.total_draws
    @first_draw = Draw.order(:contest_number).first
    @last_draw = Draw.order(:contest_number).last

    analyzer_name =
      @selected_analysis == "overview" ? :frequency : @selected_analysis.to_sym

    @result = MegaSena::Statistics::Runner.new(
      analyzer_names: [analyzer_name]
    ).call

    # O Runner agrupa os resultados dentro da chave :analyses.
    @analysis = @result.dig(:analyses, analyzer_name)

    # Os rankings da frequência também alimentam a visão geral.
    frequency = analyzer_name == :frequency ? @analysis : nil

    @top_numbers =
      frequency&.dig(:rankings, :most_frequent)&.first(10) || []

    @least_numbers =
      frequency&.dig(:rankings, :least_frequent)&.first(10) || []
  end

  def run
    analysis = params[:analysis].to_s

    unless ANALYSES.key?(analysis)
      redirect_to statistics_path, alert: "Análise estatística inválida."
      return
    end

    redirect_to statistics_path(analysis: analysis), status: :see_other
  end
end
