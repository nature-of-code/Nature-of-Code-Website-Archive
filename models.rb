
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