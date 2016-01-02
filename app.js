'use strict'

// Load the .env file if we aren't in production
if (process.env.ENV !== 'production') { require('dotenv').load() }

var _ = require('lodash')
var path = require('path')
var http = require('http')
var basicAuth = require('basic-auth')
var bodyParser = require('body-parser')
var ejs = require('ejs')
var express = require('express')
var https = require('https')
var pg = require('pg')
var numeral = require('numeral')

var dbString = process.env.DATABASE_URL || "postgres://localhost:5432/natureofcode"

var adminRouter = express.Router()
var app = express()

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(express.static(path.join(__dirname, 'public')))
app.set('view engine', 'ejs')
app.set('port', process.env.PORT)

// Basic Auth middleware for the console. Since the site is static html, the trigger to
// basic auth will happen when the client side attempts to load data via ajax.
var auth = function (req, res, next) {
  function unauthorized (res) {
    res.set('WWW-Authenticate', 'Basic realm=Authorization Required')
    return res.sendStatus(401)
  }

  var user = basicAuth(req)

  if (!user || !user.name || !user.pass) {
    return unauthorized(res)
  }

  if (user.name === process.env.ADMIN_USER && user.pass === process.env.ADMIN_PASSWORD) {
    return next()
  } else {
    return unauthorized(res)
  }
}

adminRouter.use(auth)
adminRouter.get('/', function (req, res) {
  pg.connect(dbString, (err, client, done) => {
    // Handle connection errors
    if(err) {
      done();
      console.log(err);
      return res.status(500).json({ success: false, data: err});
    }

    // some serious work can be done here with the messy callbacks
    client.query(`select
        max(amount) as maxamount,
        count(*) as ordercount,
        sum(amount) as amounttotal,
        sum(donation_amount) as donationtotal
      from orders`, function(err, results) {
      let aggregates = results.rows[0]

      client.query(`select
          count(amount) as paidcount,
          avg(amount) as avgamount,
          avg(donation_amount) as avgdonation,
          count(stripe_id) as stripecount,
          count(paypal_token) as paypalcount
        from orders where amount > 0`, (err, results) => {

        let feestotal = aggregates.amounttotal * 0.029 + results.rows[0].paidcount * 0.30
        let formattedValues = {
          ordercount: numeral(aggregates.ordercount).format('0,0'),
          paidcount: numeral(results.rows[0].paidcount).format('0,0'),
          freecount: numeral(aggregates.ordercount - results.rows[0].paidcount).format('0,0'),
          amounttotal: numeral(aggregates.amounttotal).format('$0,0.00'),
          donationtotal: numeral(aggregates.donationtotal).format('$0,0.00'),
          maxamount: numeral(aggregates.maxamount).format('$0,0.00'),
          paidorders: numeral(results.rows[0].paidcount).format('0,0'),
          authortotal: numeral(aggregates.amounttotal - aggregates.donationtotal - feestotal).format('$0,0.00'),
          avgamount: numeral(results.rows[0].avgamount).format('$0,0.00'),
          avgdonation: numeral(results.rows[0].avgdonation).format('$0,0.00'),
          feestotal: numeral(feestotal).format('$0,0.00'),
          stripecount: numeral(results.rows[0].stripecount).format('0,0'),
          paypalcount: numeral(results.rows[0].paypalcount).format('0,0'),
          paidorderslink: process.env.PAID_ORDERS_LINK,
          donationorderslink: process.env.DONATION_ORDERS_LINK
        }

        res.render('dashboard', formattedValues)
      })

    })
  })
})

app.use('/admin', adminRouter)

app.get('/', function (req, res) {
  // Special case for development, render the index file.
  if (process.env.ENV != "production") {
    res.sendFile('public/index.html')
  } else {
    // In production, this app runs at https://natureofcode.herokuapp.com, but the index
    // is hosted on Github Pages, so redirect traffic to Github Pages
    res.redirect('http://natureofcode.com')
  }
})

// POST '/order'
// The order form on natureofcode.com submits to this page where payment options are
// selected
app.post('/order', function (req, res) {
  var amount = req.body.amount
  var donation = req.body.donation
  var paying = amount > 0 ? true : false

  res.render('order', {
    paying: paying,
    amount: amount,
    donation: donation
  })
})

// POST '/purchase'
// Receives the order submission from `/order`. Determine by the passed params if the
// order was placed with Stripe or PayPal
app.post('/purchase', function (req, res) {
  if (req.body.order_type === 'free') {

  } else if (req.body.order_type === 'paypal') {
    // code to process paypal payment
  } else if (req.body.order_type === 'stripe') {
    // code to process stripe payment
  } else {
    res.status(500).render('unsuccessful')
  }
  res.send("hi")
})

// Callback route for Stripe to confirm purchase
app.post('/hook/stripe', function (req, res) {
  // confirm stripe charge succeeded
  // create fetch order
  res.sendStatus(500)
})

// Callback route for after completing payment process with Paypal
app.get('/hook/paypal', function (req, res) {
  // confirm PayPal details
  // charge PayPal account
  // verify charge succeeded
  // create fetch order

  res.sendStatus(500)
})

// Resulting pages the user is redirected to after `/purchase`
app.get('purchased/success', function (req, res) {
  res.render('successful')
})

app.get('purchased/error', function (req, res) {
  res.render('unsuccessful')
})

var server = http.createServer(app)
server.listen(process.env.PORT)
server.on('listening', function () {
  console.log('listening on ' + process.env.PORT)
})
