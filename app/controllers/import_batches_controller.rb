
class ImportBatchesController < ApplicationController
  MAX_FILE_SIZE = 10.megabytes

  def index
    @import_batches = ImportBatch.order(created_at: :desc)
  end

  def new
    @import_batch = ImportBatch.new
  end

  def show
    @import_batch = ImportBatch.find(params[:id])
  end

  def create
    uploaded_file = params[:file]

    unless valid_upload?(uploaded_file)
      redirect_to new_import_batch_path, alert: @upload_error
      return
    end

    importer = MegaSena::XlsxImporter.new(uploaded_file.tempfile.path)
    @import_batch = importer.call

    # Preserva o nome original enviado pelo usuário.
    unless importer.duplicate_file
      @import_batch.update!(file_name: File.basename(uploaded_file.original_filename))
    end

    if @import_batch.failed?
      flash[:alert] = "A importação foi rejeitada. Consulte os detalhes dos erros."
    elsif importer.duplicate_file
      flash[:notice] = "Este arquivo já foi importado anteriormente. Nenhum registro foi alterado."
    else
      run_historical_validation

      if @validation_report[:status] == "failed"
        flash[:warning] = "Importação concluída, mas a auditoria encontrou erros no histórico."
      elsif @validation_report[:status] == "warning"
        flash[:warning] = "Importação concluída com avisos na auditoria do histórico."
      else
        flash[:notice] = "Importação concluída e histórico validado com sucesso."
      end
    end

    redirect_to import_batch_path(@import_batch)
  rescue StandardError => e
    Rails.logger.error(
      "[ImportBatchesController#create] #{e.class}: #{e.message}"
    )

    redirect_to new_import_batch_path,
                alert: "Não foi possível processar o arquivo. Consulte o log da aplicação."
  end

  private

  def valid_upload?(file)
    unless file.respond_to?(:tempfile) && file.respond_to?(:original_filename)
      @upload_error = "Selecione um arquivo XLSX."
      return false
    end

    unless File.extname(file.original_filename).downcase == ".xlsx"
      @upload_error = "O arquivo deve estar no formato XLSX."
      return false
    end

    if file.size.zero?
      @upload_error = "O arquivo enviado está vazio."
      return false
    end

    if file.size > MAX_FILE_SIZE
      @upload_error = "O arquivo excede o tamanho máximo de 10 MB."
      return false
    end

    true
  end

  def run_historical_validation
    @validation_report = MegaSena::HistoricalValidator.new.call

    @import_batch.update!(
      validation_report: @validation_report
    )
  end
end
