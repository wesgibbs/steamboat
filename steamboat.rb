# Will launch one browser window, do the navigation and form completion. Next
# it will launch NUMBER_OF_INSTANCES tabs, each one with the completed form
# (because the form details are in the session). Then it will wait until the
# `go_time` to click the Reserve button as fast as the processor and Selenium
# can iterate through the tabs.
#
# Invocation:
#   bundle exec ruby ./steamboat.rb dune camper 83
#   bundle exec ruby ./steamboat.rb sage tent 312
#   bundle exec ruby ./steamboat.rb sage camper 23 test

require 'pry-byebug'
require 'selenium-webdriver'
require 'time'

class Steamboat

  NUMBER_OF_INSTANCES = 70

  attr_accessor :campground, :driver, :instance_number, :site, :tab, :tent, :test_run, :wait_long

  def initialize(driver, instance_number, tab)
    self.campground = ARGV[0]
    self.driver = driver
    self.instance_number = instance_number
    self.site = ARGV[2]
    self.tab = tab
    self.tent = ARGV[1]
    self.test_run = ARGV[3]
    self.wait_long = Selenium::WebDriver::Wait.new(:timeout => 1800) # 30 minutes
  end

  def navigate
    driver.switch_to.window(tab)
    if campground.downcase == "sage"
      driver.get "https://washington.goingtocamp.com/SteamboatRockStatePark/SageLoop(1-50,301-312)?Map"
    else
      driver.get "https://washington.goingtocamp.com/SteamboatRockStatePark/DuneLoop(51-100,313-326)?Map"
    end
  end

  def fill_out_form
    # Section 2

    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selArrMth")).select_by(:text, "Jul")
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selArrDay")).select_by(:text, ordinal_day_of_month)
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selNumNights")).select_by(:text, "3")

    # Section 3

    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "MainContentPlaceHolder_LocationList")).select_by(:text, "Steamboat Rock State Park")
    wait_long.until { driver.find_element(:id, "MainContentPlaceHolder_MapList").enabled? }
    if campground.downcase == "sage"
      Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "MainContentPlaceHolder_MapList")).select_by(:text, "Sage Loop (1-50, 301-312)")
    else
      Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "MainContentPlaceHolder_MapList")).select_by(:text, "Dune Loop (51-100, 313-326)")
    end

    # Section 4

    wait_long.until { driver.find_element(:id, "selEquipmentSub").enabled? }
    if tent.downcase == "tent"
      Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selEquipmentSub")).select_by(:text, "Tent")
    else
      Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selEquipmentSub")).select_by(:value, "Lg Trailer/Motorhome 18-32ft")
    end

    wait_long.until { driver.find_element(:id, "selPartySize").enabled? }
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selPartySize")).select_by(:value, "5")

    wait_long.until { driver.find_element(:id, "selResource").enabled? }
    Selenium::WebDriver::Support::Select.new(driver.find_element(:id, "selResource")).select_by(:text, site)
  end

  def reserve
    driver.switch_to.window(tab)
    erroring = true
    while erroring do
      begin
        wait_long.until { driver.find_element(:id, reserve_or_details).enabled? }
        driver.find_element(:id, reserve_or_details).click
        puts "Instance #{instance_number} succeeded at #{Time.now.strftime("%H:%M:%S.%L")}"
        erroring = false
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        puts "Instance #{instance_number} re-clicking..."
      end
    end
    # wait_long.until { driver.title.downcase.start_with? "never gonna happen" }
  end

  private

  def ordinal_day_of_month
    number = Date.today.strftime("%d")
    abs_number = number.to_i.abs

    ordinal = if (11..13).include?(abs_number % 100)
      "th"
    else
      case abs_number % 10
        when 1; "st"
        when 2; "nd"
        when 3; "rd"
        else    "th"
      end
    end
    "#{number}#{ordinal}"
  end

  def reserve_or_details
    test_run.downcase == "test" ? "rceDetailLink" : "reserveButton"
  end

end

go_time = Time.parse("#{Date.today.to_s} 06:59:55.001 -0700")
start = Time.now
driver = Selenium::WebDriver.for(:chrome)
steamboats = []

Steamboat::NUMBER_OF_INSTANCES.times do |index|
  instance_number = index + 1
  tab = driver.window_handles.last
  steamboat = Steamboat.new(driver, instance_number, tab)
  steamboats << steamboat
  steamboat.navigate
  steamboat.fill_out_form if instance_number == 1
  puts "Instance #{instance_number} ready"
  driver.execute_script("window.open()") unless index == Steamboat::NUMBER_OF_INSTANCES - 1
end

puts "Set up complete: #{Time.at(Time.now - start).strftime("%M:%S")}"
puts "Waiting for go time: #{go_time}"

while Time.now < go_time do
  sleep 0.005
end

steamboats.each do |steamboat|
  steamboat.reserve
end

binding.pry

driver.quit
