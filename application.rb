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
  property :first_name, String
  property :last_name, String
  property :email, String
  property :stripe_id, String
  property :fetch_id, String
  property :amount, Float
  property :donation, Integer
  property :donated, Boolean

end

DataMapper.finalize
DataMapper.auto_upgrade!

class NatureOfCode < Sinatra::Base
  get '/' do
    puts request.inspect
    File.read(File.join('public','index.html'))
  end

  post '/order' do
    puts request.inspect
    @amount = params[:amount]
    @donation = params[:donation]
    @amount = @amount.to_f
    @paying = true unless @amount == 0.0

    erb :order
  end

  post '/purchase' do
    @order = Order.new(
      amount: 0,
      donation: 0,
      email: params[:order][:email],
      first_name: params[:order][:first_name],
      last_name: params[:order][:last_name])

    if params[:order][:free] == 'true'
      fetch = create_fetch_order({
        first_name: @order.first_name,
        last_name: @order.last_name,
        email: @order.email
      }, '001')
      @order.fetch_id = fetch.id
      @order.save
    else
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

      @order[:stripe_id] = charge.id
      @order[:donation] = params[:order][:donation]
      @order[:amount] = params[:order][:amount]
      @order.save
    end
    erb :purchased
  end

  post '/deliver' do
    event_json = JSON.parse(request.body.read, symbolize_names: true)
    # Get event from Stripe API to ensure validity.
    event = Stripe::Event.retrieve(event_json[:id])
    @order = Order.first(stripe_id: event.data.object[:id])

    fetch = create_fetch_order({
      first_name: @order.first_name,
      last_name: @order.last_name,
      email: @order.email
    }, '001')

    @order.fetch_id = fetch.id
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
  # admin page for donations
end