class HoboMigration1 < ActiveRecord::Migration
  def self.up
    create_table :skype_users do |t|
      t.string   :name
      t.string   :username
      t.string   :extension
      t.string   :status
      t.string   :keywords
      t.datetime :created_at
      t.datetime :updated_at
    end
    
    create_table :users do |t|
      t.string   :crypted_password, :limit => 40
      t.string   :salt, :limit => 40
      t.string   :remember_token
      t.datetime :remember_token_expires_at
      t.string   :name
      t.string   :email_address
      t.boolean  :administrator, :default => false
      t.datetime :created_at
      t.datetime :updated_at
      t.string   :state, :default => "active"
      t.datetime :key_timestamp
    end
  end

  def self.down
    drop_table :skype_users
    drop_table :users
  end
end
