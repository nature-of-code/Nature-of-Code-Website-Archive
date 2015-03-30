require 'bundler'
Bundler.require

Stripe.api_key = ENV['STRIPE_SECRET']

require './models'
require './helpers'

class NatureOfCode < Sinatra::Base
  error do
    email_body = ""
    email_body += env['sinatra.error'].name +"\n"
    email_body += env['sinatra.error'].message +"\n"
    email_body += env['sinatra.error'].backtrace.join("\n")
    send_email("ERROR: #{request.fullpath}", email_body)
    erb :error
  end

  get '/' do
    return File.read(File.join('public','index.html')) if ENV['RACK_ENV'] == "development"
    redirect 'http://natureofcode.com'
  end

  post '/order' do
    @amount = params[:amount].to_f
    @donation = params[:donation]

    # If amount is 0, serve up order form without credit card info
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

  get '/purchase/success' do
    erb :purchased
  end

  # Paypal error callback url
  get '/purchase/error' do
    erb :unsuccessful
  end

  # ADMIN DASHBOARD
  #____________________________________________________________________________
  get '/admin/?' do
    protected!

    @order_count, @total_revenue, @total_donations, @max_purchase = Order.completed.aggregate(:all.count, :amount.sum, :donation_amount.sum, :amount.max)

    @paid_count = Order.completed.count(:amount.not => 0.0)
    @free_count = @order_count - @paid_count
    @total_fees = Order.completed.fees_total

    @orders = Order.completed.all(:limit => 2000, :paid => true, :order => [:created_at.desc])

    erb :dashboard
  end

  get '/admin/orders.csv' do
    protected!
    content_type :text
    @orders = Order.completed
    erb :orders_csv, layout:false
  end

  post '/admin/mark-paid/?' do
    protected!
    @orders = Order.all(donated: false).update(donated: true)
    redirect '/admin'
  end
end
