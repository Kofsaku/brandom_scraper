namespace :scraping do
  desc "Scrape all products"
  task all: [:prada_mens, :prada_womens] do
    puts "All scraping tasks completed."
  end

  #PRADA
  desc "Scrape Prada men's products"
  task prada_mens: :environment do
    list_url = "https://www.gebnegozionline.com/en_jp/men/designers/prada.html"
    Scraper.new.scrape_all_products(list_url)
  end

  desc "Scrape Prada women's products"
  task prada_womens: :environment do
    list_url = "https://www.gebnegozionline.com/en_jp/women/designers/prada.html"
    Scraper.new.scrape_all_products(list_url)
  end


  desc "Scrape Prada women's products"
  task prada_womens: :environment do
    list_url = "https://www.gebnegozionline.com/en_jp/women/designers/prada.html"
    Scraper.new.scrape_all_products(list_url)
  end


  #

end
