
require "test_helper"
require "tempfile"
require "digest"

class MegaSena::XlsxImporterTest < ActiveSupport::TestCase
  setup do
    @date_1 = Date.new(2025, 1, 1)
    @date_2 = Date.new(2025, 1, 8)

    @record_1 = {
      contest_number: 1,
      draw_date: @date_1,
      number_1: 1,
      number_2: 2,
      number_3: 3,
      number_4: 4,
      number_5: 5,
      number_6: 6
    }

    @record_2 = {
      contest_number: 2,
      draw_date: @date_2,
      number_1: 7,
      number_2: 8,
      number_3: 9,
      number_4: 10,
      number_5: 11,
      number_6: 12
    }
  end

  test "importa concursos novos e ignora concursos idênticos" do
    Draw.create!(@record_1)

    records = [
      [2, @record_1],
      [3, @record_2]
    ]

    with_xlsx_file do |path|
      batch = run_import(path, records)

      assert_equal "succeeded", batch.status
      assert_equal 2, batch.total_rows
      assert_equal 1, batch.inserted_rows
      assert_equal 0, batch.updated_rows
      assert_equal 1, batch.skipped_rows
      assert_equal 0, batch.error_rows

      assert_equal 2, Draw.count
      assert Draw.exists?(contest_number: 2)
    end
  end

  test "não cria um segundo lote ao importar arquivo idêntico" do
    records = [[2, @record_1]]

    with_xlsx_file do |path|
      first_batch = run_import(path, records)

      second_importer = importer_for(path, records)
      second_batch = second_importer.call

      assert_equal first_batch.id, second_batch.id
      assert second_importer.duplicate_file
      assert_equal 1, ImportBatch.count
      assert_equal 1, Draw.count
    end
  end

  test "rejeita arquivo que não possui assinatura XLSX" do
    with_xlsx_file("arquivo inválido") do |path|
      batch = MegaSena::XlsxImporter.new(path).call

      assert_equal "failed", batch.status
      assert_equal 0, batch.inserted_rows
      assert_equal 1, batch.error_rows
      assert_empty Draw.all
    end
  end

  test "rejeita divergência em concurso histórico sem inserir novos concursos" do
    Draw.create!(@record_1)

    altered_record = @record_1.merge(number_1: 60)

    records = [
      [2, altered_record],
      [3, @record_2]
    ]

    with_xlsx_file do |path|
      batch = run_import(path, records)

      assert_equal "failed", batch.status
      assert_equal 0, batch.inserted_rows
      assert_equal 0, batch.updated_rows
      assert_equal 0, batch.skipped_rows
      assert_equal 1, batch.error_rows

      assert_equal 1, Draw.count
      assert_equal 1, Draw.first.number_1

      assert_equal(
        "historical_conflict",
        batch.error_details.first["code"]
      )
    end
  end

  test "rejeita planilha com lacuna na numeração" do
    records = [
      [2, @record_1],
      [3, @record_2.merge(contest_number: 3)]
    ]

    with_xlsx_file do |path|
      batch = run_import(path, records)

      assert_equal "failed", batch.status
      assert_equal 0, batch.inserted_rows
      assert_equal 0, Draw.count

      assert_includes(
        batch.error_details.map { |error| error["code"] },
        "contest_gaps"
      )
    end
  end

  test "reverte toda a importação se ocorrer falha durante a gravação" do
    records = [
      [2, @record_1],
      [3, @record_2]
    ]

    with_xlsx_file do |path|
      importer = importer_for(path, records)

      # Simula falha ao chamar save! em qualquer nova instância de Draw
      Draw.class_eval do
        alias_method :original_save!, :save!
        def save!
          raise ActiveRecord::RecordInvalid.new(self)
        end
      end

      begin
        batch = importer.call

        assert_equal "failed", batch.status
        assert_equal 0, batch.inserted_rows
        assert_equal 0, Draw.count
      ensure
        # Restaura o método original após o teste
        Draw.class_eval do
          alias_method :save!, :original_save!
          remove_method :original_save!
        end
      end
    end
  end

  private

  def importer_for(path, records)
    importer = MegaSena::XlsxImporter.new(path)
    importer.instance_variable_set(:@total_rows, records.size)

    importer.define_singleton_method(:read_records) do
      records
    end

    importer
  end

  def run_import(path, records)
    importer = importer_for(path, records)
    importer.call
  end

  def with_xlsx_file(content = "PK\x03\x04")
    Tempfile.create(["mega-sena", ".xlsx"]) do |file|
      file.binmode
      file.write(content)
      file.flush

      yield file.path
    end
  end
end
