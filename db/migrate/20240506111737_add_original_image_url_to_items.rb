class AddOriginalImageUrlToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :original_image_url, :string, array: true, default: [], using: "(string_to_array(original_image_url, ','))"
  end
end
