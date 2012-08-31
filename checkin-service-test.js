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
         imprint: '\\\\bell\\Illuminate\\Engineering\\Builds\\v2-2.13-PatientPerformance',
         parameters: "NONE"
      }
      console.log(data.imprint)
      console.log(JSON.stringify(data));
      res.end(JSON.stringify(data));
   }
});

server.listen(8080);