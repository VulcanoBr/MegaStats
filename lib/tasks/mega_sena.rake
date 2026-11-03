
namespace :mega_sena do
  desc "Importa o histórico da Mega-Sena a partir de um arquivo XLSX"

  task import_xlsx: :environment do
    default_path = Rails.root.join("storage", "imports", "Mega-Sena.xlsx")
    path = ENV["MEGA_SENA_XLSX"].presence || default_path.to_s

    unless File.file?(path)
      abort(
        "Arquivo não encontrado: #{path}\n" \
        "Coloque o arquivo em storage/imports/Mega-Sena.xlsx " \
        "ou informe MEGA_SENA_XLSX=/caminho/arquivo.xlsx."
      )
    end

    importer = MegaSena::XlsxImporter.new(path)
    batch = importer.call

    puts
    puts "=== Resultado da importação MegaStats ==="
    puts "Arquivo:       #{batch.file_name}"
    puts "Status:        #{batch.status}"
    puts "Linhas lidas:  #{batch.total_rows}"
    puts "Inseridos:     #{batch.inserted_rows}"
    puts "Atualizados:   #{batch.updated_rows}"
    puts "Ignorados:     #{batch.skipped_rows}"
    puts "Com erros:     #{batch.error_rows}"

    if batch.failed?
      puts
      puts "Detalhes dos erros:"
      puts JSON.pretty_generate(batch.error_details)
      abort "Importação não concluída."
    end

    if importer.duplicate_file
      puts
      puts "Arquivo já importado anteriormente. Nenhuma alteração realizada."
      next
    end

    report = MegaSena::HistoricalValidator.new.call
    batch.update!(validation_report: report)

    puts
    puts "=== Auditoria do histórico ==="
    puts "Status:             #{report[:status]}"
    puts "Concursos verificados: #{report[:total_draws]}"
    puts "Erros:              #{report[:errors].size}"
    puts "Avisos:             #{report[:warnings].size}"

    if report[:errors].any?
      puts
      puts "Erros da auditoria:"
      puts JSON.pretty_generate(report[:errors])
    end

    if report[:warnings].any?
      puts
      puts "Avisos da auditoria:"
      puts JSON.pretty_generate(report[:warnings])
    end

    puts
    puts "Importação concluída. Relatório registrado no lote #{batch.id}."
  end
end
