'use strict'
var fs = require('fs');
var browserify = require('browserify');
var babelify = require('babelify');
var watchify = require('watchify');

let b = browserify({ debug: true, plugin: [watchify] })

let bundle = function () {
  b.transform(babelify)
    .require('./assets/js/index.js', { entry: true })
    .bundle()
    .on('error', function (err) { console.log('Error: ' + err.message); })
    .pipe(fs.createWriteStream('./public/js/index.js'));
}

b.on('update', bundle);
bundle();
