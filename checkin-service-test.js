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
      res.end("http://illum-ci-leeroy/job/ActKnowledge%20Demo%20Generation/lastSuccessfulBuild/artifact/Softek.Demo.Web.Setup/bin/Release/Softek.Demo.Web.Setup.wixlib");
   }
});

server.listen(8080);