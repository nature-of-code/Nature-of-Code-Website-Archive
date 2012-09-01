require 'bundler'
Bundler.require

Stripe.api_key = ENV['STRIPE_SECRET']

# Public: Process order information and create an order for FetchApp with
# specified information. Triggers an email to be sent from Fetch.
#
# order - A hash containing the orderer's first name, last name and email
#         address
# item  - SKU for the ordered item
#
# Returns nothing.
def create_fetch_order(orderer, item)
  FetchAppAPI::Base.basic_auth(key: ENV['FETCH_KEY'], token: ENV['FETCH_TOKEN'])
  order = FetchAppAPI::Order.create(
    title:        "#{DateTime.now}",
    first_name:   orderer[:first_name],
    last_name:    orderer[:last_name],
    email:        orderer[:email],
    order_items:  [{sku: item}]
  )
end

DataMapper.setup(:default, ENV['DATABASE_URL'])

class Order
  include DataMapper::Resource

  property :id, Serial, key: true
  property :response, Text
  property :email, String
  property :stripe_id, String
  property :fetch_id, String

end

DataMapper.finalize
DataMapper.auto_upgrade!

class NatureOfCode < Sinatra::Base
  get '/' do
    erb :index
  end

  post '/order' do
    @amount = params[:amount]
    erb :order
  end

  get '/order' do
    @amount = 10.00
    erb :order
  end

  post '/purchase' do
    # get the credit card details submitted by the form
    token = params[:order][:token]
    amount_dollars = (params[:order][:amount].to_f * 100).to_i

    # create the charge on Stripe's servers - this will charge the user's card
    charge = Stripe::Charge.create(
      :amount => amount_dollars,
      :currency => "usd",
      :card => token,
      :description => params[:order][:email]
    )
    "and..."
  end

  post '/deliver' do
    event_json = JSON.parse(request.body.read, symbolize_names: true)

    event = Stripe::Event.retrieve(event_json[:id])

    name = event.data.object[:card][:name].split(' ')
    email = event.data.object[:description]

    @order = Order.new
    @order.response = event_json.to_json
    @order.email = email

    fetch = create_fetch_order({
      first_name: name[0],
      last_name: name[1..name.length].join(" "),
      email: email
    }, '001')

    @order.fetch_id = fetch.id
    @order.stripe_id = event.data.object[:id]
    @order.save

    status 200
    body "ok"
  end

  get '/css/natureofcode.css' do
    scss :"../assets/sass/application"
  end

  get '/js/:file.js' do
    # path relative to /views
    coffee :"../assets/javascripts/#{params[:file]}"
  end

  # send email after payment
  # Resend email from Fetch if order exists
end