class AddCodeAndGenderToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :code, :string
    add_column :items, :gender, :string
  end
end
