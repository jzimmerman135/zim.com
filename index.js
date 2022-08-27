const express = require('express');

const PORT = 3593;

const app = express();
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/public'));

app.listen(PORT);

app.get('/', function(req, res) {
	res.render('pages/index');
});

app.get('/about', function(req, res) {
    res.render('pages/about')
});

