
class ImportBatch < ApplicationRecord
  has_many :draws, dependent: :restrict_with_exception

  STATUSES = %w[pending processing succeeded failed].freeze
  TERMINAL_STATUSES = %w[succeeded failed].freeze

  validates :file_name, presence: true
  validates :status, inclusion: { in: STATUSES }

  validates :total_rows,
            :inserted_rows,
            :updated_rows,
            :skipped_rows,
            :error_rows,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validate :finished_at_required_for_terminal_status

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end

  private

  def finished_at_required_for_terminal_status
    return unless TERMINAL_STATUSES.include?(status)
    return if finished_at.present?

    errors.add(:finished_at, "deve ser informado para uma importação finalizada")
  end
end
