require 'bundler'
Bundler.require

Stripe.api_key = ENV['STRIPE_SECRET']

require './models'
require './helpers'

class NatureOfCode < Sinatra::Base
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
    email_parts = params[:order][:email].split('@')

    first_name = params[:order][:first_name].length > 0 ? params[:order][:first_name] : email_parts[0]
    last_name = params[:order][:last_name].length > 0 ? params[:order][:last_name] : email_parts[0]

    @order = Order.new(
      amount: 0,
      donation: 0,
      email: params[:order][:email],
      first_name: first_name,
      last_name: last_name)

    if params[:order_type] == "free"
      fetch = create_fetch_order(@order, '001')
      @order.fetch_id = fetch.id
      @order.save
      erb :purchased
    elsif params[:order_type] == "paypal"
      # Fill in money details for purchase, use email address as description
      payment_request = Paypal::Payment::Request.new(
        :currency_code => :USD, # if nil, PayPal use USD as default
        :amount        => params[:order][:amount],
        :description   => params[:order][:email]
      )

      Paypal.sandbox!
      # Setup Paypal request with business credentials
      @paypal_request = Paypal::Express::Request.new(
        :username   => ENV['PAYPAL_USERNAME'],
        :password   => ENV['PAYPAL_PASSWORD'],
        :signature  => ENV['PAYPAL_SIGNATURE']
      )
      # Create the transaction request with payment and callback urls
      response = @paypal_request.setup(
        payment_request,
        "http://128.122.151.180:5000/purchase/confirm",
        "http://128.122.151.180:5000/purchase/error"
      )
      @order.amount = params[:order][:amount]
      @order[:donation] = params[:order][:donation]
      @order.paypal_token = response.token
      @order.save

      redirect response.redirect_uri
    # Otherwise it's a stripe order
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
    event_json = JSON.parse(request.body.read, symbolize_names: true)
    # Get event from Stripe API to ensure validity.
    event = Stripe::Event.retrieve(event_json[:id])
    @order = Order.first(stripe_id: event.data.object[:id])

    puts "Creating fetch order"

    fetch = create_fetch_order(@order, '001')

    @order.fetch_id = fetch.id
    @order.save

    status 200
    body "ok"
  end

  get '/purchase/confirm' do
    # Setup Paypal request with business credentials
    Paypal.sandbox!
    @paypal_request = Paypal::Express::Request.new(
      :username   => ENV['PAYPAL_USERNAME'],
      :password   => ENV['PAYPAL_PASSWORD'],
      :signature  => ENV['PAYPAL_SIGNATURE']
    )

    # raise params.inspect
    @order = Order.first(:paypal_token => params[:token])
    response = @paypal_request.details(@order.paypal_token)

    response = @paypal_request.checkout!(
      @order.paypal_token,
      params[:PayerID],
      Paypal::Payment::Request.new(
        :currency_code => :USD, # if nil, PayPal use USD as default
        :amount        => @order.amount,
        :description   => "@order.email"
      )
    )
    # inspect this attribute for more details
    response.payment_info

    "success"
  end

  get '/purchase/error' do
    "ohno"
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

  # For Development only.
  get '/css/natureofcode.css' do
    scss :"../assets/sass/application"
  end
end