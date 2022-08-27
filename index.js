const express = require('express');

const port = process.env.PORT || 5000;

const app = express();
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/public'));

app.get('/', function(req, res) {
	res.render('pages/index');
});

app.get('/about', function(req, res) {
    res.render('pages/about')
});

app.listen(port);
