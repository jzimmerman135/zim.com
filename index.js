const functions = require("firebase-functions");

const express = require('express');

const app = express();
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/public'));

app.get('/', function(req, res) {
	res.render('pages/index');
});

app.get('/about', function(req, res) {
    res.render('pages/about')
});

exports.app = functions.https.onRequest(app);