var http = require('http')

var server = http.createServer(function (req, res) {
   res.writeHead(200, 'OK');

   if (req.url.match(/engagement-complete/)) {
      console.log("Complete:")

      req.on('data', function (data) {
         console.log(data.toString('utf8', 0, data.length));     
         res.end();
      });

   } else if (req.url.match(/next-engagement/)) {
      console.log("Checkin: " + req.url);

      var data = {
         memory: '\\\\bell\\Illuminate\\Engineering\\Builds\\v2-2.12-Hotfix\\',
         parameters: ""
      }

      res.end(JSON.stringify(data));
   }
});

server.listen(8080);