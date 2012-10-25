#!/usr/bin/env ruby

require 'csv'
require 'fetchapp-api-ruby' # https://github.com/getsy/fetchapp-api-ruby
require 'fileutils'

if !ARGV[0]
  puts "ERROR: Please provide:"
  puts "ruby batch_fetch.rb fetch_key fetch_token some_file.csv"
  exit 1
end

fetch_key = ARGV[0]
fetch_token = ARGV[1]
csv_file_name = ARGV[2]

dir = File.dirname(__FILE__)
csv = CSV.read(File.join(dir, csv_file_name))

most_recent = nil

#TODO look for file with last-read datetime

reference_file_name = File.join(dir, "last_batch_fetch.txt")

if File.exists? reference_file_name
  previous_run = File.readlines(reference_file_name, "r+")[0]
end

FetchAppAPI::Base.basic_auth(key: fetch_key, token: fetch_token)

# Skip the first line of the csv, which is the header.
csv[1..csv.length].each do |line|
  date_entered = DateTime.parse line[0]

  if !previous_run.nil? && date_entered <= DateTime.parse(previous_run)
    next
  end

  split_name = line[1].split(" ")
  first_name = split_name.shift
  last_name = split_name.join(" ")
  email = line[2]

  most_recent = date_entered if most_recent.nil?

  if date_entered > most_recent
    most_recent = date_entered
  end

  order = FetchAppAPI::Order.create(
    title:        date_entered,
    first_name:   first_name,
    last_name:    last_name,
    email:        email,
    order_items:  [{sku: '001', price: '0.00'}]
  )

  puts "#{first_name} #{last_name} email #{date_entered}"
end

File.open(reference_file_name, "w") do |f|
  f.write most_recent
end