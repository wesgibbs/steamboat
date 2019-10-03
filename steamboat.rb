# Will launch one browser window and do the navigation. Then it will launch
# NUMBER_OF_TABS tabs and repeat the process for each tab.  Then it will wait
# until the `go_time` to click the Reserve button as fast as the processor and
# Selenium can iterate through the tabs.
#
# Invocation:
#   bundle exec ruby ./steamboat.rb dune 83
#   bundle exec ruby ./steamboat.rb sage 312
#   bundle exec ruby ./steamboat.rb sage 23 test

require 'active_support/time'
require 'pry-byebug'
require 'selenium-webdriver'
require 'time'

class Steamboat

  NUMBER_OF_TABS = 70
  NUMBER_OF_NIGHTS = 4

  attr_accessor :campground, :driver, :instance_number, :site, :tab, :test_run, :wait_long

  def initialize(driver, instance_number, tab)
    self.campground = ARGV[0]
    self.driver = driver
    self.instance_number = instance_number
    self.site = ARGV[1]
    self.tab = tab
    self.test_run = ARGV[2] || ""
    self.wait_long = Selenium::WebDriver::Wait.new(:timeout => 1800) # 30 minutes
  end

  def navigate
    begin
      driver.switch_to.window(tab)
      map_id = campground.downcase == "sage" ? "-2147483552" : "-2147483489"
      driver.get "https://washington.goingtocamp.com/create-booking/results?resourceLocationId=-2147483552&mapId=#{map_id}&searchTabGroupId=0&bookingCategoryId=0&startDate=2020-#{start_date.strftime("%m")}-#{start_date.strftime("%d")}T00:00:00.000Z&endDate=2020-#{end_date.strftime("%m")}-#{end_date.strftime("%d")}T00:00:00.000Z&nights=#{NUMBER_OF_NIGHTS}&isReserving=true&equipmentId=-32768&subEquipmentId=-32759&partySize=5"

      wait_long.until { driver.find_element(:xpath, "//*[text()='#{site}']").enabled? }
      element = driver.find_element(:xpath, "//*[text()='#{site}']")
      driver.execute_script("arguments[0].scrollIntoView();",element)

      element.click
      true
    rescue StandardError => e
      puts "Instance #{instance_number} failed to initialize. #{e.message}"
      false
    end
  end

  def reserve
    driver.switch_to.window(tab)
    erroring = true
    while erroring do
      begin
        driver.find_element(:xpath, "//span[text()='#{reserve_or_details}']").find_element(:xpath, "..").click
        puts "Instance #{instance_number} succeeded at #{Time.now.strftime("%H:%M:%S.%L")}"
        erroring = false
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        puts "Instance #{instance_number} re-clicking..."
      end
    end
  end

  private

  def end_date
    @end_date ||= start_date + NUMBER_OF_NIGHTS.days
  end

  def reserve_or_details
    @reserve_or_details ||= test_run.downcase == "test" ? "View More Details" : "Reserve"
  end

  def start_date
    @start_date ||= Date.today + 9.months
  end

end

go_time = Time.parse("#{Date.today.to_s} 06:59:55.001")
start = Time.now
driver = Selenium::WebDriver.for(:chrome)
steamboats = []

Steamboat::NUMBER_OF_TABS.times do |index|
  instance_number = index + 1
  tab = driver.window_handles.last
  steamboat = Steamboat.new(driver, instance_number, tab)
  if steamboat.navigate
    steamboats << steamboat
    puts "Instance #{instance_number} ready"
  end
  driver.execute_script("window.open()") unless index == Steamboat::NUMBER_OF_TABS - 1
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
