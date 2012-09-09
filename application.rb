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
    # File.read(File.join('public','index.html'))
    redirect 'http://natureofcode.com'
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