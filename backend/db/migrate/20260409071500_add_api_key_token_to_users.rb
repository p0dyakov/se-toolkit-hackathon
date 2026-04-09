class AddApiKeyTokenToUsers < ActiveRecord::Migration[7.2]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_column :users, :api_key_token, :string
    add_index :users, :api_key_token, unique: true

    MigrationUser.reset_column_information

    MigrationUser.find_each do |user|
      api_key_token = user.api_key_token.presence || "bsc_#{SecureRandom.hex(24)}"
      api_key_digest = Digest::SHA256.hexdigest(api_key_token)
      user.update_columns(api_key_token:, api_key_digest:)
    end

    change_column_null :users, :api_key_token, false
    change_column_null :users, :api_key_digest, false
  end

  def down
    remove_index :users, :api_key_token
    remove_column :users, :api_key_token
  end
end
