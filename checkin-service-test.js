var http = require('http')

var server = http.createServer(function (req, res) {
   res.writeHead(200, 'OK');
   res.end("http://illum-ci-leeroy/job/ActKnowledge%20Demo%20Generation/lastSuccessfulBuild/artifact/Softek.Demo.Web.Setup/bin/Release/Softek.Demo.Web.Setup.wixlib");
});

server.listen(8080);