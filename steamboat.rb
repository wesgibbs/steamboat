require 'pry-byebug'
require 'selenium-webdriver'
require 'time'

class Steamboat

  attr_accessor :driver, :instance_number, :site, :tent, :wait_long

  def initialize(instance_number)
    self.driver = Selenium::WebDriver.for :chrome
    self.instance_number = instance_number
    self.site = ARGV[0]
    self.tent = ARGV[1]
    self.wait_long = Selenium::WebDriver::Wait.new(:timeout => 1800) # 30 minutes
  end

  def prepare
    driver.get "https://washington.goingtocamp.com/SteamboatRockStatePark?Map"

    # Section 2

    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selArrMth")).select_by(:text, "Jul")
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selArrDay")).select_by(:text, "22nd")
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

    puts "Instance #{instance_number} ready"
  end

  def reserve
    driver.find_element(:id, "reserveButton").click
    wait_long.until { driver.title.downcase.start_with? "never gonna happen" }
  end

end

steamboats = Array.new(3) do |instance_number|
  Steamboat.new(instance_number + 1)
end

steamboats.each do |steamboat|
  fork { steamboat.prepare }
  sleep 3
end

go_time = Time.parse "2018-10-22 13:37:01.001 -0700"

while Time.now < go_time do
  sleep 0.005
end

steamboats.each do |steamboat|
  puts "Instance #{steamboat.instance_number} firing at #{Time.now.strftime("%H:%M:%S.%L")}"
  fork { steamboat.reserve }
  sleep 0.02
end

sleep 60 * 30 # 30 minutes
