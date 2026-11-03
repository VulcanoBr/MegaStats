
require "digest"
require "date"
require "bigdecimal"
require "roo"

module MegaSena
  class XlsxImporter
    MAX_FILE_SIZE = 10 * 1024 * 1024

    REQUIRED_HEADERS = %w[
      concurso
      data_do_sorteio
      bola1
      bola2
      bola3
      bola4
      bola5
      bola6
    ].freeze

    COLUMN_MAP = {
      "concurso" => [:contest_number, :integer],
      "data_do_sorteio" => [:draw_date, :date],

      "bola1" => [:number_1, :integer],
      "bola2" => [:number_2, :integer],
      "bola3" => [:number_3, :integer],
      "bola4" => [:number_4, :integer],
      "bola5" => [:number_5, :integer],
      "bola6" => [:number_6, :integer],

      "ganhadores_6_acertos" => [:winners_sena, :integer],
      "rateio_6_acertos" => [:prize_sena, :decimal],

      "ganhadores_5_acertos" => [:winners_quina, :integer],
      "rateio_5_acertos" => [:prize_quina, :decimal],

      "ganhadores_4_acertos" => [:winners_quadra, :integer],
      "rateio_4_acertos" => [:prize_quadra, :decimal],

      "cidade_uf" => [:city_uf, :string],
      "acumulado_6_acertos" => [:accumulated_sena, :decimal],
      "arrecadacao_total" => [:total_revenue, :decimal],
      "estimativa_premio" => [:estimated_prize, :decimal],

      "acumulado_sorteio_especial_mega_da_virada" =>
        [:special_draw_accumulated, :decimal],

      "observacao" => [:observation, :string]
    }.freeze

    REQUIRED_ATTRIBUTES = %i[
      contest_number
      draw_date
      number_1
      number_2
      number_3
      number_4
      number_5
      number_6
    ].freeze

    INTEGER_ATTRIBUTES = %i[
      winners_sena
      winners_quina
      winners_quadra
    ].freeze

    DECIMAL_ATTRIBUTES = %i[
      prize_sena
      prize_quina
      prize_quadra
      accumulated_sena
      total_revenue
      estimated_prize
      special_draw_accumulated
    ].freeze

    DRAW_NUMBER_ATTRIBUTES = (1..6).map do |number|
      :"number_#{number}"
    end.freeze

    attr_reader :duplicate_file

    def initialize(path)
      @path = path.to_s
      @errors = []
      @total_rows = 0
      @duplicate_file = false
      @batch = nil
    end

    def call
      validate_file_exists!

      file_sha256 = Digest::SHA256.file(@path).hexdigest

      previous_batch = ImportBatch.find_by(
        file_sha256: file_sha256,
        status: "succeeded"
      )

      if previous_batch
        @duplicate_file = true
        return previous_batch
      end

      @batch = ImportBatch.create!(
        file_name: File.basename(@path),
        file_sha256: file_sha256,
        status: "processing",
        started_at: Time.current
      )

      validate_file_format!

      records = read_records

      if @errors.any?
        return fail_import
      end

      if records.empty?
        add_error(
          code: "empty_workbook",
          message: "A planilha não contém registros para importação."
        )

        return fail_import
      end

      load_existing_draws!(records)
      validate_complete_history!(records)
      validate_existing_draws!(records)

      @batch.update!(total_rows: @total_rows)

      return fail_import if @errors.any?

      inserted = 0
      skipped = 0

      ActiveRecord::Base.transaction do
        records.each do |_row_number, attributes|
          draw = Draw.find_by(
            contest_number: attributes.fetch(:contest_number)
          )

          if draw
            skipped += 1
            next
          end

          new_draw = Draw.new(attributes)
          new_draw.import_batch = @batch
          new_draw.save!

          inserted += 1
        end

        @batch.update!(
          status: "succeeded",
          total_rows: @total_rows,
          inserted_rows: inserted,
          updated_rows: 0,
          skipped_rows: skipped,
          error_rows: 0,
          error_details: [],
          finished_at: Time.current
        )
      end

      @batch
    rescue StandardError => e
      raise if @batch.nil?

      add_error(
        code: "import_exception",
        message: "#{e.class}: #{e.message}"
      )

      fail_import
    end

    private

    # ------------------------------------------------------------------
    # Arquivo
    # ------------------------------------------------------------------

    def validate_file_exists!
      unless File.file?(@path)
        raise ArgumentError, "Arquivo não encontrado: #{@path}"
      end
    end

    def validate_file_format!
      extension = File.extname(@path).downcase

      unless extension == ".xlsx"
        raise ArgumentError, "Formato inválido. Selecione um arquivo XLSX."
      end

      size = File.size(@path)

      if size.zero?
        raise ArgumentError, "O arquivo está vazio."
      end

      if size > MAX_FILE_SIZE
        raise ArgumentError, "O arquivo ultrapassa o limite de 10 MB."
      end

      signature = File.binread(@path, 4)

      unless signature.start_with?("PK")
        raise ArgumentError,
              "O arquivo não possui uma assinatura válida de arquivo XLSX."
      end
    end

    # ------------------------------------------------------------------
    # Leitura da planilha
    # ------------------------------------------------------------------

    def read_records
      workbook = Roo::Excelx.new(@path)

      sheet_name = workbook.sheets.find do |name|
        normalize_header(name) == "mega_sena"
      end

      unless sheet_name
        raise ArgumentError,
              "A planilha não contém uma aba chamada MEGA SENA."
      end

      sheet = workbook.sheet(sheet_name)

      if sheet.last_row.nil? || sheet.last_row < 2
        raise ArgumentError,
              "A aba MEGA SENA não contém registros."
      end

      headers = sheet.row(1).map do |header|
        normalize_header(header)
      end

      validate_headers!(headers)

      records = []
      seen_contests = {}

      (2..sheet.last_row).each do |row_number|
        values = sheet.row(row_number)

        next if values.all? do |value|
          value.nil? || value.to_s.strip.empty?
        end

        @total_rows += 1

        begin
          row = headers.zip(values).to_h
          attributes = extract_attributes(row)

          validate_record!(attributes)

          contest_number = attributes.fetch(:contest_number)

          if seen_contests.key?(contest_number)
            raise ArgumentError,
                  "Concurso #{contest_number} duplicado na planilha."
          end

          seen_contests[contest_number] = true

          records << [row_number, attributes]
        rescue StandardError => e
          add_error(
            row: row_number,
            code: "invalid_row",
            message: e.message
          )
        end
      end

      records
    end

    def extract_attributes(row)
      attributes = {}

      COLUMN_MAP.each do |header, (attribute, type)|
        next unless row.key?(header)

        attributes[attribute] = parse_value(row[header], type)
      end

      attributes
    end

    # ------------------------------------------------------------------
    # Cabeçalhos
    # ------------------------------------------------------------------

    def validate_headers!(headers)
      if headers.all?(&:blank?)
        raise ArgumentError,
              "A primeira linha não contém cabeçalhos."
      end

      duplicated_headers = headers.compact
                                  .reject(&:blank?)
                                  .tally
                                  .select { |_header, count| count > 1 }
                                  .keys

      if duplicated_headers.any?
        raise ArgumentError,
              "Cabeçalhos duplicados: #{duplicated_headers.join(', ')}"
      end

      missing_headers = REQUIRED_HEADERS - headers

      if missing_headers.any?
        raise ArgumentError,
              "Cabeçalhos obrigatórios ausentes: " \
              "#{missing_headers.join(', ')}"
      end
    end

    def normalize_header(value)
      value.to_s
           .unicode_normalize(:nfkd)
           .gsub(/\p{Mn}/, "")
           .strip
           .downcase
           .gsub(/[^\p{Alnum}]+/, "_")
           .gsub(/\A_+|_+\z/, "")
    end

    # ------------------------------------------------------------------
    # Conversão dos valores
    # ------------------------------------------------------------------

    def parse_value(value, type)
      return nil if value.nil? || value.to_s.strip.empty?

      case type
      when :integer
        parse_integer(value)
      when :date
        parse_date(value)
      when :decimal
        parse_decimal(value)
      when :string
        value.to_s.strip.presence
      else
        value
      end
    end

    def parse_integer(value)
      text = value.to_s.strip

      return nil if ["-", "--"].include?(text)

      if value.is_a?(Numeric)
        raise ArgumentError unless value.to_i == value

        return value.to_i
      end

      Integer(text, 10)
    rescue ArgumentError, TypeError
      raise ArgumentError,
            "Número inteiro inválido: #{value.inspect}"
    end

    def parse_date(value)
      date =
        case value
        when DateTime, Time
          value.to_date
        when Date
          value
        when Numeric
          # Número serial de data do Excel.
          Date.new(1899, 12, 30) + value.to_i
        else
          text = value.to_s.strip

          begin
            Date.strptime(text, "%d/%m/%Y")
          rescue Date::Error, ArgumentError
            begin
              Date.iso8601(text)
            rescue Date::Error, ArgumentError
              raise ArgumentError,
                    "Data inválida: #{value.inspect}"
            end
          end
        end

      if date > Date.current
        raise ArgumentError,
              "A data do sorteio não pode ser futura: " \
              "#{date.strftime('%d/%m/%Y')}."
      end

      date
    end

    def parse_decimal(value)
      return nil if value.nil?

      if value.is_a?(Numeric)
        decimal = BigDecimal(value.to_s)
        raise ArgumentError unless decimal.finite?

        return decimal
      end

      text = value.to_s.strip
      return nil if ["-", "--"].include?(text)

      text = text.gsub(/[^\d,.-]/, "")

      if text.include?(",")
        text = text.delete(".").tr(",", ".")
      end

      decimal = BigDecimal(text)

      unless decimal.finite?
        raise ArgumentError
      end

      decimal
    rescue ArgumentError, TypeError
      raise ArgumentError,
            "Valor monetário inválido: #{value.inspect}"
    end

    # ------------------------------------------------------------------
    # Validação individual
    # ------------------------------------------------------------------

    def validate_record!(attributes)
      missing = REQUIRED_ATTRIBUTES.select do |attribute|
        attributes[attribute].nil?
      end

      if missing.any?
        raise ArgumentError,
              "Campos obrigatórios vazios: #{missing.join(', ')}"
      end

      unless attributes[:contest_number].positive?
        raise ArgumentError,
              "O número do concurso deve ser positivo."
      end

      numbers = DRAW_NUMBER_ATTRIBUTES.map do |attribute|
        attributes.fetch(attribute)
      end

      unless numbers.all? do |number|
        number.is_a?(Integer) && (1..60).cover?(number)
      end
        raise ArgumentError,
              "Todas as dezenas devem ser inteiros entre 1 e 60."
      end

      unless numbers.uniq.size == 6
        raise ArgumentError,
              "O concurso contém dezenas repetidas."
      end

      INTEGER_ATTRIBUTES.each do |attribute|
        value = attributes[attribute]
        next if value.nil?

        unless value.is_a?(Integer) && value >= 0
          raise ArgumentError,
                "#{attribute} deve ser um inteiro não negativo."
        end
      end

      DECIMAL_ATTRIBUTES.each do |attribute|
        value = attributes[attribute]
        next if value.nil?

        unless value >= 0
          raise ArgumentError,
                "#{attribute} não pode ser negativo."
        end
      end
    end

    # ------------------------------------------------------------------
    # Validação global da planilha
    # ------------------------------------------------------------------

    def validate_complete_history!(records)
      ordered = records.sort_by do |_row_number, attributes|
        attributes.fetch(:contest_number)
      end

      contest_numbers = ordered.map do |_row_number, attributes|
        attributes.fetch(:contest_number)
      end

      expected_numbers = (1..contest_numbers.last).to_a

      missing_numbers = expected_numbers - contest_numbers

      if missing_numbers.any?
        add_error(
          code: "contest_gaps",
          message: "Concursos ausentes na planilha: " \
                   "#{missing_numbers.first(50).join(', ')}"
        )
      end

      dates = {}

      ordered.each do |row_number, attributes|
        contest = attributes.fetch(:contest_number)
        date = attributes.fetch(:draw_date)

        if dates.key?(date)
          add_error(
            row: row_number,
            code: "duplicate_draw_date",
            message: "A data #{date.strftime('%d/%m/%Y')} " \
                     "também está associada ao concurso #{dates[date]}."
          )
        else
          dates[date] = contest
        end
      end

      ordered.each_cons(2) do |previous, current|
        previous_row, previous_attributes = previous
        current_row, current_attributes = current

        previous_date = previous_attributes.fetch(:draw_date)
        current_date = current_attributes.fetch(:draw_date)

        next if current_date > previous_date

        add_error(
          row: current_row,
          code: "invalid_chronology",
          message: "A data do concurso " \
                   "#{current_attributes[:contest_number]} " \
                   "não é posterior à data do concurso " \
                   "#{previous_attributes[:contest_number]}."
        )
      end

      database_max = Draw.maximum(:contest_number)

      if database_max && contest_numbers.last < database_max
        add_error(
          code: "stale_workbook",
          message: "A planilha termina no concurso " \
                   "#{contest_numbers.last}, mas o banco já possui " \
                   "o concurso #{database_max}."
        )
      end
    end

    def load_existing_draws!(records)
      contest_numbers = records.map do |_row_number, attributes|
        attributes.fetch(:contest_number)
      end

      @existing_draws = Draw.where(
        contest_number: contest_numbers
      ).index_by(&:contest_number)
    end

    # ------------------------------------------------------------------
    # Comparação com os concursos existentes
    # ------------------------------------------------------------------

    def validate_existing_draws!(records)
      records.each do |row_number, attributes|
        draw = @existing_draws[attributes.fetch(:contest_number)]

        next unless draw

        differences = attributes.filter_map do |attribute, value|
          next if attribute == :contest_number

          database_value = draw.public_send(attribute)

          normalized_value =
            Draw.type_for_attribute(attribute.to_s).cast(value)

          next if database_value == normalized_value

          {
            attribute: attribute,
            database_value: database_value,
            spreadsheet_value: normalized_value
          }
        end

        next if differences.empty?

        descriptions = differences.map do |difference|
          "#{difference[:attribute]}: " \
            "banco=#{difference[:database_value].inspect}, " \
            "planilha=#{difference[:spreadsheet_value].inspect}"
        end

        add_error(
          row: row_number,
          code: "historical_conflict",
          message: "O concurso #{attributes[:contest_number]} " \
                   "diverge do banco de dados. " \
                   "#{descriptions.join('; ')}"
        )
      end
    end

    # ------------------------------------------------------------------
    # Registro de erros e finalização
    # ------------------------------------------------------------------

    def add_error(**details)
      @errors << details
    end

    def fail_import
      @batch.update!(
        status: "failed",
        total_rows: @total_rows,
        inserted_rows: 0,
        updated_rows: 0,
        skipped_rows: 0,
        error_rows: @errors.size,
        error_details: @errors,
        finished_at: Time.current
      )

      @batch
    end
  end
end
