class CreateDraws < ActiveRecord::Migration[8.1]
  def change
    create_table :draws do |t|
      t.integer :contest_number, null: false
      t.date :draw_date, null: false

      (1..6).each do |number|
        t.integer :"number_#{number}", null: false
      end

      t.integer :winners_sena
      t.decimal :prize_sena, precision: 15, scale: 2

      t.integer :winners_quina
      t.decimal :prize_quina, precision: 15, scale: 2

      t.integer :winners_quadra
      t.decimal :prize_quadra, precision: 15, scale: 2

      t.string :city_uf

      t.decimal :accumulated_sena, precision: 15, scale: 2
      t.decimal :total_revenue, precision: 15, scale: 2
      t.decimal :estimated_prize, precision: 15, scale: 2

      t.decimal :special_draw_accumulated,
                precision: 15,
                scale: 2

      t.text :observation

      t.jsonb :source_metadata, null: false, default: {}

      t.references :import_batch,
                   null: true,
                   foreign_key: true

      t.timestamps
    end

    add_index :draws, :contest_number, unique: true
    add_index :draws, :draw_date
    add_index :draws, :total_revenue

    add_check_constraint :draws,
                         "contest_number > 0",
                         name: "draws_contest_number_positive"

    (1..6).each do |number|
      add_check_constraint :draws,
                           "number_#{number} BETWEEN 1 AND 60",
                           name: "draws_number_#{number}_valid"
    end

    add_check_constraint :draws,
                         [
                           "number_1 <> number_2",
                           "number_1 <> number_3",
                           "number_1 <> number_4",
                           "number_1 <> number_5",
                           "number_1 <> number_6",
                           "number_2 <> number_3",
                           "number_2 <> number_4",
                           "number_2 <> number_5",
                           "number_2 <> number_6",
                           "number_3 <> number_4",
                           "number_3 <> number_5",
                           "number_3 <> number_6",
                           "number_4 <> number_5",
                           "number_4 <> number_6",
                           "number_5 <> number_6"
                         ].join(" AND "),
                         name: "draws_numbers_are_distinct"
  end
end