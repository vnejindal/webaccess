var http = require('http');  
var fs = require('fs');

//vne:: added automatically by script
var webip = '127.0.0.1'
var webport = 8000


server = http.createServer(function(req, res) {  


	fs.readFile("index.html", function(err, data){
  		res.writeHead(200, {'Content-Type': 'text/html'});
  		res.write(data);
  		res.end();
	});
}).listen(webport, webip, function() {
	console.log("ready on "+ server.address().port);
});

console.log('Server running at http://127.0.0.1:8000');

var Promise = require('bluebird');
var readFile = Promise.promisify(require("fs").readFile);
//tty.js
var tty = require('tty.js');

readFile("ttyconfig.json", "utf8").then(function(data) {
	var ttycfg = JSON.parse(data);
        var ttyapp = tty.createServer(ttycfg);
	ttyapp.listen();
});


