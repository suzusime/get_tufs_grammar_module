#!/usr/bin/env ruby
# -- coding: utf-8
require 'nokogiri'
require 'open-uri'
require 'fileutils'

OUTPUT_DIR='./gmod_out'
SLEEP = 0.1 # ダウンロードごとの待機時間
LANGLIST = [
  ["en", "英語"],
  ["de", "ドイツ語"],
  ["fr", "フランス語"],
  ["es", "スペイン語"],
  ["pt", "ポルトガル語"],
  ["ru", "ロシア語"],
  ["zh", "中国語"],
  ["ko", "朝鮮語"],
  ["mn", "モンゴル語"],
  ["id", "インドネシア語"],
  ["tl", "フィリピノ語"],
  ["lo", "ラオス語"],
  ["vi", "ベトナム語"],
  ["km", "カンボジア語"],
  ["ur", "ウルドゥー語"],
  ["ar", "アラビア語（フスハー）"],
  ["ar-eg", "アラビア語（エジプト方言）"],
  ["ar-sy", "アラビア語（シリア方言）"],
  ["tr", "トルコ語"],
  ["ja", "日本語"],
]

# 言語モジュールの各カードの内容を結合したHTMLをつくって返す
#doc = Nokogiri::HTML(URI.open("http://www.coelang.tufs.ac.jp/mt/fr/gmod/steplist.html"), nil, 'UTF-8')
def get_merged_card_page(lang, number_text, title)
  mother_doc = Nokogiri::XML("<div class=\"merged\"><h1>#{title}</h1></div>", nil, 'UTF-8')
  mother = mother_doc.at_css('.merged')
  [["card", "<< カード >>"], ["explanation", "<< 解説 >>"], ["instances", "<< 例文 >>"]].each do |type_pair|
    type, type_name = type_pair
    url = "http://www.coelang.tufs.ac.jp/mt/#{lang}/gmod/contents/#{type}/#{number_text}.html"
    begin
      doc = Nokogiri::HTML(URI.open(url), nil, 'UTF-8')
      contents = doc.css(".contents").first
      mother << "<h2>#{type_name}</h2>"
      mother << contents
    rescue OpenURI::HTTPError => error
      # 404が返る場合があるのだが、その場合は握りつぶす
    end
  end
  mother.css(".voiceLinkBox").remove
  return mother_doc
end

# 文法モジュールのステップ一覧を取得
def get_gmod_index(lang)
  url = "http://www.coelang.tufs.ac.jp/mt/#{lang}/gmod/steplist.html"
  doc = Nokogiri::HTML(URI.open(url), nil, 'UTF-8')
  gmod_index = Array.new
  doc.css("ul.ulist>li.list").each do |li|
    a = li.at_css("a")
    num_text = /(\d+).html$/.match(a['href']).to_a[1]
    title = a.text
    #puts "#{num_text}: #{title}"
    gmod_index.append([num_text, title])
  end
  return gmod_index
end

# 文法モジュールのダウンロード
def download_grammar_module(lang, langname)
  puts "#{langname}文法モジュールのダウンロード中..."
  lang_dir = "#{OUTPUT_DIR}/#{lang}"
  FileUtils.mkdir_p(lang_dir)

  # 目次の生成
  gmod_index = get_gmod_index(lang)
  index_page = Nokogiri::HTML("<html><head><title>#{langname}文法モジュール</title></head><body><h1>#{langname}文法モジュール</h1><ol></ol></body></html>")
  index_list = index_page.at_css("ol")
  gmod_index.each do |li|
    num_text, title = li
    index_list.add_child("<li><a href=\"#{num_text}.html\">#{title}</a></li>")
  end
  File.open("#{lang_dir}/index.html", 'w') do |f|
    f.print(index_page.to_html)
  end

  # 各ページのダウンロード
  gmod_index.each do |li|
    num_text, title = li
    pagedoc = get_merged_card_page(lang, num_text, title)
    File.open("#{lang_dir}/#{num_text}.html", 'w') do |f|
      f.print(pagedoc.to_html)
    end
    sleep(SLEEP)
  end
  puts "#{langname}文法モジュールのダウンロード完了."
end

def main
  index_page = Nokogiri::HTML("<html><head><title>東京外国語大学言語モジュール > 文法モジュール</title></head><body><h1>東京外国語大学言語モジュール > 文法モジュール</h1><ol></ol></body></html>")
  index_list = index_page.at_css("ol")
  LANGLIST.each do |li|
    lang, langname = li
    index_list.add_child("<li><a href=\"#{lang}/index.html\">#{langname}</a></li>")
  end
  FileUtils.mkdir_p(OUTPUT_DIR)
  File.open("#{OUTPUT_DIR}/index.html", 'w') do |f|
    f.print(index_page.to_html)
  end
  
  LANGLIST.each do |l|
    lang, langname = l
    download_grammar_module(lang, langname)
  end
end

if __FILE__ == $0
  main
end
