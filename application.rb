require 'bundler'
Bundler.require

Stripe.api_key = ENV['STRIPE_SECRET']

require './models'
require './helpers'

class NatureOfCode < Sinatra::Base

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
      @order.paid = true
      @order.save
      erb :purchased
    elsif params[:order_type] == "paypal"
      # Fill in money details for purchase, use email address as description
      payment_request = Paypal::Payment::Request.new(
        :currency_code => :USD, # if nil, PayPal use USD as default
        :amount        => params[:order][:amount],
        :description   => params[:order][:email]
      )

      # Setup Paypal request with business credentials
      @paypal_request = Paypal::Express::Request.new(
        :username   => ENV['PAYPAL_USERNAME'],
        :password   => ENV['PAYPAL_PASSWORD'],
        :signature  => ENV['PAYPAL_SIGNATURE']
      )
      # Create the transaction request with payment and callback urls
      response = @paypal_request.setup(
        payment_request,
        "https://natureofcode.herokuapp.com/purchase/confirm",
        "https://natureofcode.herokuapp.com/purchase/error"
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

      puts charge

      @order[:stripe_id] = charge.id
      @order[:donation] = params[:order][:donation]
      @order[:amount] = params[:order][:amount]
      @order.save
      redirect '/purchase/success'
    end
  end

  # Stripe webhook URL
  post '/deliver' do
    event_json = JSON.parse(request.body.read, symbolize_names: true)
    # Get event from Stripe API to ensure validity.
    event = Stripe::Event.retrieve(event_json[:id])

    @order = Order.first(stripe_id: event.data.object[:id])

    # If we found the order, create a fetch order.
    if !@order.nil?
      puts "Creating fetch order"
      fetch = create_fetch_order(@order, '001')
      @order.fetch_id = fetch.id
      @order.paid = true
      @order.save
    elsif ["transfer.paid", "transfer.created"].include? event.type
      puts "transfer paid"
    else
      send_email("stripe request for non-existing record", "#{event.type}\n#{event.data.object['type']}\n#{event.data.object}")
    end

    status 200
    body "ok"
  end

  # Paypal success callback url
  get '/purchase/confirm' do
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

    fetch = create_fetch_order(@order, '001')
    @order.fetch_id = fetch.id
    @order.paid = true
    @order.save

    redirect '/purchase/success'
  end
end
