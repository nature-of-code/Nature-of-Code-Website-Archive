require 'bundler'
Bundler.require

# Public: Process order information and create an order for FetchApp with
# specified information. Triggers an email to be sent from Fetch.
#
# order - A hash containing the orderer's first name, last name and email
#         address
# item  - SKU for the ordered item
#
# Returns nothing.
def create_fetch_order#(orderer, item)
  FetchAppAPI::Base.basic_auth(key: ENV['FETCH_KEY'], token: ENV['FETCH_TOKEN'])
  order = FetchAppAPI::Order.create(
    title:        "#{DateTime.now}",
    first_name:   orderer['first_name'],
    last_name:    orderer['last_name'],
    email:        orderer['email'],
    order_items:  [{sku: item}]
  )
end

class NatureOfCode < Sinatra::Base
  get '/' do
    redirect '/index.html'
  end

  get '/order' do
    erb :order
  end

  get '/js/:file.js' do
    # path relative to /views
    coffee :"../assets/javascripts/#{params[:file]}"
  end

  # send email after payment
  # Resend email from Fetch if order exists
end