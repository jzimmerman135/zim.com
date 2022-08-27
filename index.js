const express = require('express');

const port = process.env.PORT || 5000;
const app = express();
app.set('view engine', 'ejs');
app.use(express.static(__dirname + '/public'));

app.get('/', function(req, res) {
	res.render('pages/index');
});

app.get('/about', function(req, res) {
    res.render('pages/about');
});

app.get('/template', function(req, res) {
    res.render('pages/about');
});

app.get('/webgl', function(req, res) {
    res.render('pages/webgl');
})

console.log(`starting up on port: ${port}`);
app.listen(port);
