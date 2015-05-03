// Load the .env file if we aren't in production
if (process.env.ENV !== 'production') { require('dotenv').load() }

var path = require('path')
var http = require('http')
var basicAuth = require('basic-auth')
var bodyParser = require('body-parser')
var ejs = require('ejs')
var express = require('express')
var https = require('https')

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

  res.render('order', {
    paying: amount === 0.0 ? false : true,
    amount: amount,
    donation: donation
  })
})

// POST '/purchase'
// Receives the order submission from `/order`. Determine by the passed params if the
// order was placed with Stripe or PayPal
app.post('/purchase', function (req, res) {

})

// Callback route for Stripe to confirm purchase
app.post('/hook/stripe', function (req, res) {})

// Callback route for after completing payment process with Paypal
app.get('/hook/paypal', function (req, res) {})

// Resulting pages the user is redirected to after `/purchase`
app.get('purchased/success', function (req, res) {
  res.render('purchased')
})

app.get('purchased/error', function (req, res) {})

var server = http.createServer(app)
server.listen(process.env.PORT)
server.on('listening', function () {
  console.log('listening on ' + process.env.PORT)
})
