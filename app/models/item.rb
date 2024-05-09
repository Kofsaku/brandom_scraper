require 'csv'

class Item < ApplicationRecord
  has_many_attached :images

  def self.export_to_csv
    csv_data = to_csv
    file_path = Rails.root.join('tmp', 'items.csv')

    File.open(file_path, 'w') do |file|
      file.write(csv_data)
    end

    file_path
  end

  def self.to_csv
    attributes = %w[brand name size title price description url]
    CSV.generate(headers: true) do |csv|
      csv << CSV_PRODUCT_TEMPLATE_HEADERS

      Item.all.each do |item|
        max_rows = [item.size.count, item.images.count].max

        max_rows.times do |index|
          row = Array.new(CSV_PRODUCT_TEMPLATE_HEADERS.size, '')

          if index.zero?
            row[0] = item.name.parameterize
            row[1] = item.title
            row[2] = item.description
            row[3] = item.brand
            # row[4] = 'Apparel & Accessories > Clothing'
            # row[5] = 'Shirts'
            row[6] = "#{item.brand}, #{item.url}, #{item.gender}, #{item.code}"
            row[7] = 'TRUE'
            row[8] = 'サイズ'
            row[9] = item.size[index] if item.size[index]
            row[14] = "#{item.name.parameterize}-#{item.size[index]}" if item.size[index]
            row[16] = 'shopify'
            row[17] = item.price == 0 ? '0' : '5'
            row[18] = 'deny'
            row[19] = 'manual'
            row[20] = item.price
            row[25] = item.original_image_url[index] if item.original_image_url[index]
            row[26] = index + 1
            row[28] = 'FALSE'
            row[45] = 'kg'
            row[46] = 'TRUE'
            row[50] = 'active'
          else
            # バリエーションがなく、画像しかない時は以下で良さそう。バリエーションがある場合は、バリエーションのための金額を表示した理する必要がありそうなので対応必要
            row[0] = item.name.parameterize
            if item.size[index]
              row[9] = item.size[index]
              row[14] = "#{item.name.parameterize}-#{item.size[index]}"
              row[16] = 'shopify'
              row[17] = item.price == 0 ? '0' : '5'
              row[18] = 'deny'
              row[19] = 'manual'
              row[20] = item.price
            end
            row[25] = item.original_image_url[index] if item.original_image_url[index]
            row[26] = index + 1
            row[28] = 'FALSE'
            row[50] = 'active'
          end

          csv << row
        end
      end
    end
  end
end


# 画像部分のURLがあっているのか
# csvのURLについて
  #デプロイしてしまったほうが早いかもしれない。
