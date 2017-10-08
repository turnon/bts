require "bts/version"
require 'capybara/poltergeist'
require 'pry'

class Bts

  URL =  'http://btkitty.pet/'

  attr_reader :browser, :keyword

  class << self
    def search keyword
      bts = new keyword
      bts.do_search
      binding.pry
    rescue => e
      binding.pry
    end
  end

  def initialize keyword
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(
        app, js_errors: false, phantomjs_options: ['--load-images=no']
      )
    end

    Capybara.default_driver = :poltergeist

    @browser = Capybara.current_session
    @keyword = keyword
    @tried = 0
  end

  def do_search
    get_hash_url
    fetch_others_pages
  end

  def get_hash_url
    browser.visit URL
    fill_in_keyword
    browser.find_button('Search').trigger('click')
  end

  def fill_in_keyword
    browser.fill_in 'keyword', with: keyword
  rescue => e
    raise e if @tried > 10
    sleep 3
    @tried += 1
    retry
  end

  def fetch_others_pages
    browser.has_css? '.pagination'
    collect_result
    hash, type = browser.current_url.split('/1/0/')
    (2..([10, max_page].min)).each do |page|
      next_page = [hash, page, 0, type].join('/')
      browser.visit next_page
      collect_result
    end
  end

  def collect_result
    puts browser.current_url
  end

  def max_page
    browser.all('.pagination span')[0].text.gsub(/[^\d]/, '').to_i
  end

  def method_missing *args
    browser.send *args
  end

end
