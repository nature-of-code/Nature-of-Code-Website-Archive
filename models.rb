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
  property :amount, Float, default: 0
  property :donation, Integer
  property :donation_amount, Float
  property :donated, Boolean, default: false
  property :paid, Boolean, default: false

  property :created_at, DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!
