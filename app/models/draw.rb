class Draw < ApplicationRecord
  belongs_to :import_batch, optional: true

  validates :contest_number,
            presence: true,
            uniqueness: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :draw_date, presence: true

  validates :number_1, :number_2, :number_3,
            :number_4, :number_5, :number_6,
            presence: true,
            inclusion: { in: 1..60 }

  validates :winners_sena,
            :winners_quina,
            :winners_quadra,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :prize_sena,
            :prize_quina,
            :prize_quadra,
            :accumulated_sena,
            :total_revenue,
            :estimated_prize,
            :special_draw_accumulated,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validate :numbers_must_be_distinct

  private

  def numbers_must_be_distinct
    numbers = [
      number_1, number_2, number_3,
      number_4, number_5, number_6
    ]

    return if numbers.any?(&:nil?)
    return if numbers.uniq.size == 6

    errors.add(:base, "Os seis números devem ser distintos")
  end
end