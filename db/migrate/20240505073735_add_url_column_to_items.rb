class AddUrlColumnToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :url, :string
  end
end
