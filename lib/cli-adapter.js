'use strict';

var minimist = require('minimist');
var Hexo = require('hexo');

var args = minimist(process.argv.slice(2));
var cwd = args.cwd;
var hexo = new Hexo(cwd, {
  silent: true
});

delete args.cwd;

hexo.init().then(function() {
  var cmd = args._.shift();
  var c = hexo.extend.console.get(cmd);

  if (c) {
    hexo.call(cmd, args).then(function() {
      if (cmd === 'publish') {
        hexo.emit('publishAfter');
      }

      return hexo.exit();
    }).catch(function(err) {
      return hexo.exit(err);
    });
  } else {
    console.error('Hexo command not found.');
  }
});

hexo.on('new', function(post) {
  console.log(JSON.stringify({
    event: 'new',
    message: post.path
  }));
});

hexo.on('generateAfter', function() {
  console.log(JSON.stringify({
    event: 'generateAfter'
  }));
});

hexo.on('deployAfter', function() {
  console.log(JSON.stringify({
    event: 'deployAfter'
  }));
});

hexo.on('publishAfter', function() {
  console.log(JSON.stringify({
    event: 'publishAfter'
  }));
});

hexo.on('exit', function(err) {
  if (err) {
    console.error(err);
  }
});
