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
    order_items:  [{sku: item, price:orderer[:amount]}]
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
  property :paypal_token, String
  property :amount, Float
  property :donation, Integer
  property :donated, Boolean, default: false

  property :created_at, DateTime

  def self.fees_total
    total = 0
    all.each do |order|
      if order.amount > 0
        # Subtract Stripe fee as well as donation
        total += 0.029 * order.amount + 0.30
      end
    end
    total
  end

  def self.author_total
    total = 0
    all.each do |order|
      if order.amount > 0
        # Subtract Stripe fee as well as donation
        total += (1 - order.donation.to_f/100.0 - 0.029) * order.amount - 0.30
      end
    end
    total
  end

  def self.donation_total
    total = 0
    all.each do |order|
      total += (order.donation.to_f/100.0 * order.amount)
    end
    total
  end

  def donation_amount
    amount * donation / 100.0
  end

  def author_amount
    amount - donation_amount
  end

end

DataMapper.finalize
DataMapper.auto_upgrade!

class NatureOfCode < Sinatra::Base
  helpers do

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['ADMIN_USERNAME'], ENV['ADMIN_PASSWORD']]
    end

  end

  get '/' do
    File.read(File.join('public','index.html'))
    # redirect 'http://natureofcode.com'
  end

  post '/order' do
    @amount = params[:amount]
    @donation = params[:donation]
    @amount = @amount.to_f
    @paying = true unless @amount == 0.0

    erb :order
  end

  post '/purchase' do

    puts "Shiffman: purchasing"

    email_parts = params[:order][:email].split('@')

    first_name = params[:order][:first_name].length > 0 ? params[:order][:first_name] : email_parts[0]
    last_name = params[:order][:last_name].length > 0 ? params[:order][:last_name] : email_parts[0]

    @order = Order.new(
      amount: 0,
      donation: 0,
      email: params[:order][:email],
      first_name: first_name,
      last_name: last_name)

    if params[:order][:free] == 'true'
      fetch = create_fetch_order({
        first_name: @order.first_name,
        last_name: @order.last_name,
        email: @order.email
      }, '001')
      @order.fetch_id = fetch.id
      @order.save
      erb :purchased
    elsif params[:order][:paypal] == 'true'
      # Setup Paypal request with business credentials
      request = Paypal::Express::Request.new(
        :username   => ENV['PAYPAL_USERNAME'],
        :password   => ENV['PAYPAL_PASSWORD'],
        :signature  => ENV['PAYPAL_SIGNATURE']
      )
      # Fill in money details for purchase, use email address as description
      payment_request = Paypal::Payment::Request.new(
        :currency_code => :USD, # if nil, PayPal use USD as default
        :amount        => params[:order][:amount],
        :description   => params[:order][:email]
      )
      # Create the transaction request with payment and callback urls
      response = request.setup(
        payment_request,
        "http://128.122.151.180:5000/purchase/confirm",
        "http://128.122.151.180:5000/purchase/error"
      )

      @order.paypal_token = response.token
      @order.save

      redirect response.redirect_uri
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
      erb :purchased
    end
  end

  post '/deliver' do
    puts "Shiffman: delivering"


    event_json = JSON.parse(request.body.read, symbolize_names: true)
    # Get event from Stripe API to ensure validity.
    event = Stripe::Event.retrieve(event_json[:id])
    @order = Order.first(stripe_id: event.data.object[:id])

    puts "Creating fetch order"

    fetch = create_fetch_order({
      first_name: @order.first_name,
      last_name: @order.last_name,
      email: @order.email,
      amount: @order.amount
    }, '001')

    @order.fetch_id = fetch.id
    @order.save

    status 200
    body "ok"
  end

  get '/purchase/confirm' do
    raise params.inspect
    response = request.details(params[:token])
    # inspect these attributes for more details
    response.payer
    response.amount
    response.ship_to
    response.payment_responses

    response = request.checkout!(
      params[:token],
      params[:payer_id],
      payment_request
    )
    # inspect this attribute for more details
    response.payment_info

    puts "success"
  end

  get '/purchase/error' do
    "ohno"
  end

  get '/css/natureofcode.css' do
    scss :"../assets/sass/application"
  end

  get '/admin/?' do
    protected!
    @orders = Order.all
    @undonated = @orders.all(:donated.not => true)
    @paid = @orders.all(:amount.not => 0.0)
    @free = @orders.all(:amount => 0.0)
    erb :dashboard
  end

  get '/admin/orders.csv' do
    protected!
    content_type :text
    @orders = Order.all
    erb :orders_csv, layout:false
  end

  post '/admin/mark-paid/?' do
    protected!
    @orders = Order.all(donated: false).update(donated: true)
    redirect '/admin'
  end

  # send email after payment
  # Resend email from Fetch if order exists
end