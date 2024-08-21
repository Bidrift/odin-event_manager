require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  clean_number = number.split('').select { |v| v.match?(/^[0-9]$/) }.join
  clean_number.size == 10 || clean_number.size == 11 && clean_number[0] == "1" ? clean_number[-10..] : "Bad number"
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_reg_hour(regtimes)
    hour_freq = regtimes.reduce(Hash.new(0)) do |a, v|
      a[v.hour] += 1
      a
    end
    hour_freq.select { |k, v| v == hour_freq.values.max }.keys
end

def peak_reg_days(regtimes)
  day_freq = regtimes.reduce(Hash.new(0)) do |a, v|
    a[v.strftime("%A")] += 1
    a
  end
  day_freq.select { |k, v| v == day_freq.values.max }.keys
end

regtimes = []


contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone_number(row[:homephone])
  regtimes.push(Time.strptime(row[:regdate], "%m/%d/%y %k:%M"))

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "Peak registration hour(s) are #{peak_reg_hour(regtimes).join(", ")}"
puts "Peak registration day(s) are #{peak_reg_days(regtimes).join(", ")}"