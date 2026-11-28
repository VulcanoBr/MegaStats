class RandomDrawsController < ApplicationController
  # GET /random_draw                          → tela inicial
  # GET /random_draw?numbers=04-17-23-35-41-58 → resultado e análise (link compartilhável / atualizável)
  def show
    return if params[:numbers].blank?

    numbers = parse_numbers(params[:numbers])

    if numbers
      @analysis = MegaSena::RandomDrawAnalysis.new(numbers).call
    else
      flash.now[:alert] = "Informe seis dezenas distintas entre 01 e 60."
    end
  end

  # POST /random_draw → sorteia e redireciona (evita repetir o sorteio ao atualizar a página)
  def create
    numbers = MegaSena::RandomDrawGenerator.call
    redirect_to random_draw_path(numbers: numbers.map { |n| format("%02d", n) }.join("-")),
                status: :see_other
  end

  private

  def parse_numbers(raw)
    numbers = raw.to_s.split(/[^0-9]+/).reject(&:empty?).map(&:to_i)
    valid = numbers.size == 6 && numbers.uniq.size == 6 && numbers.all? { |n| n.between?(1, 60) }
    valid ? numbers.sort : nil
  end
end
