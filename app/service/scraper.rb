require 'selenium-webdriver'
require 'open-uri'

class Scraper
  BRAND_URLS = {
    moncler_men:  "https://www.gebnegozionline.com/en_jp/men/designers/moncler.html",
    moncler_women:  "https://www.gebnegozionline.com/en_jp/women/designers/moncler.html",
    versace_men:  "https://www.gebnegozionline.com/en_jp/men/designers/versace.html",
    versace_women:  "https://www.gebnegozionline.com/en_jp/women/designers/versace.html",
    bottega_veneta_men:  "https://www.gebnegozionline.com/en_jp/men/designers/bottega-veneta.html",
    bottega_veneta_women:  "https://www.gebnegozionline.com/en_jp/women/designers/bottega-veneta.html",
    givenchy_men:  "https://www.gebnegozionline.com/en_jp/men/designers/givenchy.html",
    givenchy_women:  "https://www.gebnegozionline.com/en_jp/women/designers/givenchy.html",

    prada_men: "https://www.gebnegozionline.com/en_jp/men/designers/prada.html",
    prada_women: "https://www.gebnegozionline.com/en_jp/women/designers/prada.html",
    loewe_men: "https://www.gebnegozionline.com/en_jp/men/designers/loewe.html",
    loewe_women: "https://www.gebnegozionline.com/en_jp/catalogsearch/result/?q=Loewe",
    burberry_men: "https://www.gebnegozionline.com/en_jp/men/designers/burberry.html",
    burberry_women: "https://www.gebnegozionline.com/en_jp/women/designers/burberry.html",
    fendi_men: "https://www.gebnegozionline.com/en_jp/men/designers/fendi.html",
    fendi_women: "https://www.gebnegozionline.com/en_jp/women/designers/fendi.html",
    balenciage_men:  "https://www.gebnegozionline.com/en_jp/men/designers/balenciaga.html",
    balenciage_women:  "https://www.gebnegozionline.com/en_jp/women/designers/balenciaga.html",
    margiela_men:  "https://www.gebnegozionline.com/en_jp/men/designers/maison-margiela.html",
    margiela_women:  "https://www.gebnegozionline.com/en_jp/women/designers/maison-margiela.html",


  }.freeze

  def initialize
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    @driver = Selenium::WebDriver.for(:chrome, options: options)
  end

  def update_images
    items = Item.where(original_image_url: [])
    items.each do |item|
      url = item.url
      @driver.get(url)
      original_image_url = @driver.find_elements(css: ".product__gallery__img").map do |e|
        e.attribute("src")
      end
      item.update(original_image_url: original_image_url)
    end
  end

  def scrape_new_products(list_url)
    all_items = []
    product_urls = fetch_all_product_details_urls(list_url)
    product_urls.each do |product_url|
      unless item_exists?(product_url)
        all_items.concat(create_products_from_url(product_url))
      else
        puts "#{product_url}はすでに存在します。スキップします。"
      end
    end
    all_items
  end

  def scrape_all_new_brands
    all_brands_urls_list.each do |brand, url_list|
      scrape_new_products(url_list)
    end
  end

  def scrape_all_brands
    all_brands_urls_list.each do |brand, url_list|
      scrape_all_products(url_list)
    end
  end

  def scrape_all_products(list_url)
    all_items = []
    product_urls = fetch_all_product_details_urls(list_url)
    product_urls.each do |product_url|
      all_items.concat(create_products_from_url(product_url))
    end
    all_items
  end

  def create_products_from_url(product_url)
    items = []
    move_to_product_details_page(product_url)
    if page_exists?
      product_info = extract_product_info
      item = create_product(product_info)
      items << item

      if has_other_colors?
        other_color_urls = fetch_other_color_urls
        other_color_urls.each do |color_url|
          move_to_product_details_page(color_url)
          product_info = extract_product_info
          item = create_product(product_info)
          items << item
        end
      end
    end
    items
  end

  def create_product(product_info)
    item = Item.find_or_initialize_by(url: product_info[:url])
    item.update(product_info.except(:images, :url))
    attach_images(item, product_info[:images])
    puts "#{item.url}を#{item.persisted? ? '更新' : '作成'}しました"
    item
  end

  def attach_images(item, image_paths)
    image_paths.each do |path|
      item.images.attach(io: File.open(path), filename: File.basename(path))
    end
  end

  private

  def page_exists?
    @driver.find_elements(css: ".product-title-name").present?
  end

  def item_exists?(product_url)
    Item.exists?(url: product_url)
  end

  def all_brands_urls_list
    BRAND_URLS
  end

  def move_to_product_details_page(product_url)
    @driver.get(product_url)
  end

  def extract_product_info
    puts "今はここです。#{@driver.current_url}"
    parameter = {
      url: @driver.current_url,
      brand: brand,
      name: product_name,
      price: price,
      title: "#{brand} | #{product_name}",
      description: description,
      size: size,
      images: images,
      original_image_url: original_image_url
    }
    parameter
  end

  def original_image_url
    @driver.find_elements(css: ".product__gallery__img").map do |e|
      e.attribute("src")
    end
  end

  def fetch_all_product_details_urls(list_url)
    @driver.get(list_url)
    product_list_urls = []

    loop do
      product_list_urls.concat(extract_product_urls)
      puts @driver.current_url
      next_page_element = @driver.find_elements(css: ".item.pages-item-next").first
      break unless next_page_element
      next_page_link = next_page_element.find_element(tag_name: "a")
      url = next_page_link.attribute("href")
      @driver.get(url)
    end
    puts product_list_urls
    product_list_urls
  end


  def extract_product_urls
    elements = @driver.find_elements(class: "product-item-photo")
    elements.map { |e| e.attribute("href") }
  end

  def has_other_colors?
    @driver.find_elements(css: ".swatch-color").present?
  end

  def fetch_other_color_urls
    @driver.find_elements(css: ".swatch-color").map do |e|
      e.attribute("href")
    end.drop(1)
  end

  def brand
    @driver.find_elements(css: ".product-title-name")&.first&.text
  end

  def product_name
    @driver.find_elements(css: ".page-title-wrapper.designer").first.text
  end

  def price
    price_text = @driver.find_elements(css: ".price")&.first&.text
    price_text&.gsub(/[^0-9]/, '').to_i || 0
  end

  def size
    options = @driver.find_elements(css: ".super-attribute-select option")
    sizes = options.drop(1) # 最初の"Choose an Option..."を除外
                    .reject { |option| option.text.downcase.include?('sold out') } # 'Sold Out'を含むオプションを除外
                    .map(&:text)
  end


  def description
    @driver.find_element(css: ".product-info-detailed-description.small-12.mage-accordion-disabled").text
  end

  def url
    @driver.current_url
  end

  def images
    @driver.find_elements(css: ".product__gallery__img").map do |e|
      url = e.attribute("src")
      temp_file = URI.open(url)
      # 画像をダウンロードして一時ファイルに保存
      filename = "#{SecureRandom.hex(8)}.jpg"
      File.open(Rails.root.join("tmp/#{filename}"), 'wb') do |file|
        file.write(temp_file.read)
      end
      # 一時ファイルのパスを返す
      Rails.root.join("tmp/#{filename}")
    end
  end
end
