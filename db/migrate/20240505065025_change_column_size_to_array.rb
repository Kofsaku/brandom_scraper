class ChangeColumnSizeToArray < ActiveRecord::Migration[7.0]
  def change
    change_column :items, :size, :string, array: true, default: '{}', using: "(string_to_array(size, ','))"
  end
end
