class NatureOfCode < Sinatra::Base
  helpers do
    def send_email(email_subject, email_body)
      Pony.mail({
        to: ENV['MAIN_EMAIL'],
        cc: ENV['BACKUP_EMAIL'],
        from: ENV['MAILGUN_SMTP_LOGIN'],
        via: :smtp,
        via_options: {
          address:                ENV['MAILGUN_SMTP_SERVER'],
          port:                   ENV['MAILGUN_SMTP_PORT'],
          enable_starttls_auto:   true,
          user_name:              ENV['MAILGUN_SMTP_LOGIN'],
          password:               ENV['MAILGUN_SMTP_PASSWORD'],
          authentication:         :plain,
          domain:                 'heroku.com'
        },
        subject: email_subject,
        body: email_body
      })
    end

    # Public: Process order information and create an order for FetchApp with
    # specified information. Triggers an email to be sent from Fetch.
    #
    # order - A hash containing the orderer's first name, last name and email
    #         address
    # item  - SKU for the ordered item
    #
    # Returns nothing.
    def create_fetch_order(order, item)
      puts FetchAppAPI::Base.basic_auth(key: ENV['FETCH_KEY'], token: ENV['FETCH_TOKEN'])
      puts order.attributes
      puts order.email, order.first_name, order.email, order.amount
      order = FetchAppAPI::Order.create(
        title:        "#{DateTime.now}",
        first_name:   order.first_name || " ",
        last_name:    order.last_name || " ",
        email:        order.email,
        order_items:  [{
          sku: item,
          price: (order.amount || 0)
        }]
      )
    end

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
end