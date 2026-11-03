namespace :mega_sena do
  desc "Valida a integridade do histórico de concursos"

  task validate_history: :environment do
    report = MegaSena::HistoricalValidator.new.call

    puts JSON.pretty_generate(report)

    abort "Foram encontradas inconsistências críticas." if
      report[:status] == "failed"
  end
end