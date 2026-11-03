class AddValidationReportToImportBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :import_batches,
               :validation_report,
               :jsonb,
               null: false,
               default: {}
  end
end
