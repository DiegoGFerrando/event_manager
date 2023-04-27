# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

# Connect to Google API
civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

# Clean zipcode to be 5 digits
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip, civic_info)
  civic_info.representative_info_by_address(
    address: zip,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  ).officials
rescue StandardError
  'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  # Remove any non digit characters
  phone_number.delete!('^0-9')
  unless phone_number.length == 10
    if phone_number.length == 11 && phone_number[0] == 1
      phone_number[0] = ''
    else
      phone_number = ''
    end
  end
  phone_number
end

puts 'EventManager initialized.'

if File.exist? 'event_attendees.csv'
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )

  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode, civic_info)
    phone_number = clean_phone_number(row[:home_phone])

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
else
  puts 'Missing file'
end
