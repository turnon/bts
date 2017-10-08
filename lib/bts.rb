require "bts/version"
require 'capybara/poltergeist'
require 'page_by_page'
require 'pry'

class Bts

  URL =  'http://btkitty.pet/'

  attr_reader :browser, :keyword, :nodes

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
    page_by_page
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

  def page_by_page
    @nodes = PageByPage.fetch(
      url: browser.current_url.gsub(/\/1\/0\//, "/<%= n %>/#{0}/"),
      selector: '.list-con',
      to: 20
    )
  end

  def method_missing *args
    browser.send *args
  end

end
