// ------------------------------------------------------------------------------
// https://stackoverflow.com/questions/24490168/ungzip-csv-files-in-web-browser-with-javascript
//
// ------------------------------------------------------------------------------
// https://dev.to/yuvraj2112/compress-any-file-using-pako-node-js-vue-js-4kj1
//
// ------------------------------------------------------------------------------
// https://blog.daftcode.pl/how-to-make-uploading-10x-faster-f5b3f9cfcd52
//
// ------------------------------------------------------------------------------
// https://medium.com/àharrietty/zipping-and-unzipping-files-with-nodejs-375d2750c5e4
//
// ------------------------------------------------------------------------------
// https://stackoverflow.com/questions/38074288/read-gzip-stream-line-by-line

// ------------------------------------------------------------------------------
// https://stackoverflow.com/questions/50681564/gzip-a-string-in-javascript-using-pako-js
//
// ------------------------------------------------------------------------------
// https://gist.github.com/vankasteelj/ceaf706881be02452ac2
//
// ------------------------------------------------------------------------------

const fs = require('fs')
const pako = require('pako')

fs.readFile("meta.csv.gz", function(err, data) {
  if (err) throw err;
  let meta = pako.ungzip(data, { to: 'string' });
  console.log(meta);
});


