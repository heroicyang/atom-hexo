'use strict';

var minimist = require('minimist');
var Hexo = require('hexo');

var args = minimist(process.argv.slice(2));
var hexoPath = args.hexoPath;
delete args.hexoPath;

var hexo = new Hexo(hexoPath, {
  silent: true
});

hexo.init().then(function() {
  var cmd = args._.shift();
  var c = hexo.extend.console.get(cmd);

  if (c) {
    hexo.call(cmd, args).then(function() {
      switch (cmd) {
      case 'publish':
        hexo.emit('publishAfter');
        break;
      case 'clean':
        hexo.emit('cleanAfter');
        break;
      }

      return hexo.exit();
    }).catch(function(err) {
      return hexo.exit(err);
    });
  } else {
    console.error('Unsupported command.');
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

hexo.on('cleanAfter', function() {
  console.log(JSON.stringify({
    event: 'cleanAfter'
  }));
});

hexo.on('exit', function(err) {
  if (err) {
    console.error(err);
  }
});
