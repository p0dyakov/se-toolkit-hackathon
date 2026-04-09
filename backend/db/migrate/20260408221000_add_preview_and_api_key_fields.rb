class AddPreviewAndApiKeyFields < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :api_key_digest, :string

    add_column :conversions, :preview_headers, :text
    add_column :conversions, :preview_rows, :text

    add_index :users, :api_key_digest, unique: true
  end
end
