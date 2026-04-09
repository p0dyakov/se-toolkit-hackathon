class CreateConversions < ActiveRecord::Migration[7.2]
  def change
    create_table :conversions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "processing"
      t.string :original_filename, null: false
      t.string :content_type, null: false
      t.string :source_checksum
      t.text :error_message
      t.string :csv_filename

      t.timestamps
    end

    add_index :conversions, :status
    add_index :conversions, :source_checksum
  end
end
