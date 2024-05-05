class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.string :brand
      t.string :name
      t.string :size
      t.string :title
      t.decimal :price
      t.text :description

      t.timestamps
    end
  end
end
