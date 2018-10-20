require 'pry-byebug'
require 'selenium-webdriver'
require 'time'

class Steamboat

  EMAIL = "wes.signups@gmail.com"
  PWORD = ""

  attr_accessor :driver, :site, :tent, :wait_long, :wait_short

  def initialize
    self.driver = Selenium::WebDriver.for :chrome
    self.site = ARGV[0]
    self.tent = ARGV[1]
    self.wait_long = Selenium::WebDriver::Wait.new(:timeout => 900)
    self.wait_short = Selenium::WebDriver::Wait.new(:timeout => 5)
  end

  def reserve(go_time, instance_number)
    driver.get "https://washington.goingtocamp.com/SteamboatRockStatePark?Map"

    # Sign in

    # driver.find_element(:id, "SignIn").click

    # wait_short.until { driver.title.downcase.start_with? "account" }

    # email_field = driver.find_element(:id, "MainContentPlaceHolder_Login1_UserName")
    # pword_field = driver.find_element(:id, "MainContentPlaceHolder_Login1_Password")
    # email_field.send_keys EMAIL
    # pword_field.send_keys PWORD
    # driver.find_element(:id, "MainContentPlaceHolder_Login1_Login").click

    # wait_short.until { driver.title.downcase.start_with? "find a site" }

    # Section 2

    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selArrMth")).select_by(:text, "Jul")
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selArrDay")).select_by(:text, "20th")
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selNumNights")).select_by(:text, "3")

    # Section 3

    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "MainContentPlaceHolder_LocationList")).select_by(:text, "Steamboat Rock State Park")
    wait_long.until { driver.find_element(:id, "MainContentPlaceHolder_MapList").enabled? }
    # Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "MainContentPlaceHolder_MapList")).select_by(:text, "Sage Loop (1-50, 301-312)")
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "MainContentPlaceHolder_MapList")).select_by(:text, "Dune Loop (51-100, 313-326)")

    # Section 4

    wait_long.until { driver.find_element(:id, "selEquipmentSub").enabled? }
    if tent == "tent"
      Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selEquipmentSub")).select_by(:text, "Tent")
    else
      Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selEquipmentSub")).select_by(:value, "Sm Trailer up to 18ft")
    end

    wait_long.until { driver.find_element(:id, "selPartySize").enabled? }
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selPartySize")).select_by(:value, "3")

    wait_long.until { driver.find_element(:id, "selResource").enabled? }
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selResource")).select_by(:text, site)

    wait_long.until { driver.find_element(:id, "reserveButton").enabled? }

    puts "Instance #{instance_number + 1} waiting for go-time #{go_time.strftime("%H:%M:%S.%L")}"
    while Time.now < go_time do
      sleep 0.05
    end

    puts "Instance #{instance_number + 1} firing at #{Time.now.strftime("%H:%M:%S.%L")}"

    driver.find_element(:id, "reserveButton").click

    wait_long.until { driver.title.downcase.start_with? "never gonna happen" }

    driver.quit
  end

end

go_time = Time.parse "2018-10-21 06:59:55.000 -0700"

75.times do |index|
  go_time = go_time + 0.1
  fork { Steamboat.new.reserve(go_time, index) }
  sleep 2
end
