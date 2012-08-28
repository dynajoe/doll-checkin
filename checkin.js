var http = require('http')
var fs = require('fs')
var dollhouse = process.env.CI_REGISTRAR || "http://localhost:8080";
var spawn = require('child_process').spawn;

function getActiveName() {
   var parts = process.env.COMPUTERNAME.split("-")
   return parts[parts.length - 1];
}

function engagementComplete(data) {
   var request_url = url.parse(dollhouse);
   
   var post_options = { 
      host: request_url.hostname, 
      port: request_url.port, 
      path: '/engagement-complete/' + active, 
      method: 'POST'
   };

   var request = http.request(post_options);
   request.write(JSON.stringify(data));
   request.end();
}

function doImprint (active, imprint, path) {
   var installer = spawn('msiexec', ['/i', '"' + path + '"', '/quiet', 'ILLUM_SERVICEACCOUNT_PASSWORD=corncob', 'ILLUM_SERVICEACCOUNT_CONFIRM=corncob', 'DEMO_MODE=1', 'ILLUM_ADMINACCOUNT_PASSWORD=corncob'])
   var err = '';

   installer.stderr.on('data', function (data) {
      err += data;
   });

   installer.on('exit', function (code) {
      engagementComplete({ active: active, imprint: imprint, state: 'imprint', code: code, status: (code === 0 ? 'success' : 'failure'), error: err });
   });
}

var active = getActiveName();
var request_url = dollhouse + '/' + active;

http.get(request_url, function (res) {
   res.on('data', function (imprint) {
      var path = '/latest.msi';

      var stream = fs.createWriteStream(path, { 
         flags: 'w',
         encoding: null,
         mode: 0666 
      });

      stream.on('end', function () { doImprint(active, imprint, path) });

      http.get(imprint, function (res) {
         res.pipe(stream);
      }).on('error', function (e) {
         engagementComplete({ imprint: imprint, active: active, state: 'download', status: 'failure', error: e });
      });
   });
}).on('error', function (e) {
   engagementComplete({ imprint: 'Not Found', active: active, state: 'checkin', status: 'failure', error: e });
});