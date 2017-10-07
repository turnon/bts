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
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
    end

    Capybara.default_driver = :poltergeist

    @browser = Capybara.current_session
    @keyword = keyword
    @tried = 0
  end

  def do_search
    browser.visit URL
    fill_in_keyword
    browser.click_on 'Search'
  end

  def fill_in_keyword
    browser.fill_in 'keyword', with: keyword
  rescue => e
    raise e if @tried > 10
    sleep 3
    @tried += 1
    retry
  end

  def method_missing *args
    browser.send *args
  end

end
