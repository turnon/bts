require "bts/version"
require "bts/item"
require 'capybara/poltergeist'
require 'erb'
require 'pry'

class Bts

  URL =  'http://cnbtkitty.com/'
  TEMPLATE = ERB.new(File.read(File.join(__dir__, 'bts', 'table.html.erb')))
  ORDER = %i{rel add siz fil pop}

  attr_reader :browser, :keyword, :next_page, :result

  class << self
    def search(keyword, opt = {})
      bts = new keyword, opt
      bts.do_search
    rescue => e
      STDERR.puts "ERROR: #{e}", e.backtrace
    end
  end

  def initialize(keyword, opt = {})
    raise 'must specify output path' unless opt[:output]

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(
        app, js_errors: false, phantomjs_options: ['--load-images=no']
      )
    end

    Capybara.default_driver = :poltergeist

    @browser = Capybara.current_session
    @keyword = keyword
    @tried = 0
    @result = []
    @output = opt[:output]
    @page_number = opt[:number]
    @log = opt[:trace]
    @interval = opt[:interval]
    @opt = opt
  end

  def do_search
    get_hash_url
    fetch_others_pages
  ensure
    print
  end

  def get_hash_url
    browser.visit URL
    fill_in_keyword
    browser.find_button('Search').trigger('click')
  end

  def fill_in_keyword
    try do
      browser.fill_in 'keyword', with: keyword
    end
  end

  def fetch_others_pages
    browser.has_css? '.pagination'
    collect_result if default_order?
    hash, type = browser.current_url.split('/1/0/')
    (another_page..last_page).each do |page|
      @next_page = [hash, page, order, type].join('/')
      visit_next_page
    end
  end

  def another_page
    default_order? ? 2 : 1
  end

  def last_page
    [page_number, max_page].min
  end

  def visit_next_page
    try do
      sleep @interval if @interval
      browser.visit next_page
      raise "redirected to #{browser.current_url}" unless browser.current_url == next_page
      collect_result
    end
  end

  def collect_result
    log!
    browser.all('.list-con').each do |element|
      result << Item.new(element)
    end
  end

  def print
    File.open(output_path, 'w') do |f|
      f.puts TEMPLATE.result(binding)
    end
  end

  def output_path
    Pathname.new(@output).expand_path
  end

  def page_number
    @page_number || 10
  end

  def max_page
    browser.all('.pagination span')[0].text.gsub(/[^\d]/, '').to_i
  end

  def default_order?
    order == 0
  end

  def order
    @order ||= (
      order_name = @opt.find{ |o, tf| ORDER.include?(o) && tf }
      order_name = (order_name ? order_name[0] : ORDER.first)
      ORDER.index order_name
    )
  end

  def log!
    puts browser.current_url if @log
  end

  def try n = 3, interval: 3
    yield
  rescue => e
    raise e if n == 0
    sleep interval
    n -= 1
    retry
  end

  def method_missing *args
    browser.send *args
  end

end
