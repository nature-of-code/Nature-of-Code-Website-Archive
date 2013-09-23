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

  def self.fees_total
    order_count = count(:amount.not => 0.0)
    total_fees = sum(:amount) * 0.029 + order_count * 0.30
    total_fees
  end

  def self.author_total
    revenue, donations = Order.aggregate(:amount.sum, :donation_amount.sum)
    fees = fees_total
    revenue - donations - fees
  end

  def author_amount
    amount - donation_amount
  end

  def self.completed
    all(:paid => true)
  end

  def self.incomplete
    all(:paid.not => true)
  end

end

DataMapper.finalize
DataMapper.auto_upgrade!