var util = require('util');
var _ = require('lodash');
var View = require('atom').View;
var BufferedProcess = require('atom').BufferedProcess;

module.exports = AtomHexoView;

function AtomHexoView() {
  View.apply(this, arguments);
}

AtomHexoView.content = function() {
  this.div({
    'class': 'atom-hexo overlay from-bottom'
  });
};

util.inherits(AtomHexoView, View);
_.extend(AtomHexoView, View);

AtomHexoView.prototype.initialize = function(serializeState) {
  atom.workspaceView.command('keydown', this.close.bind(this));
  atom.workspaceView.command('atom-hexo:generate', this.generate.bind(this));
  atom.workspaceView.command('atom-hexo:deploy', this.deploy.bind(this));
};

AtomHexoView.prototype.destroy = function() {
  this.detach();
};

AtomHexoView.prototype.close = function(e) {
  if (e.keyCode === 27 && this.hasParent()) {
    this.detach();
  }
};

AtomHexoView.prototype.generate = function() {
  if (!this.hasParent()) {
    atom.workspaceView.prependToBottom(this);
  }

  this.html('');
  process.chdir(atom.project.getPath());

  var self = this;
  var bp = new BufferedProcess({
    command: 'hexo',
    args: ['generate'],
    stdout: function(output) {
      self.append('<div>' + output + '</div>');
      self.scrollTop(self[0].scrollHeight);
    },
    stderr: function(err) {
      self.append('<div class="warning">' + err + '</div>');
      self.scrollTop(self[0].scrollHeight);
    },
    exit: function(code) {
      if (0 === code) {
        self.append('<div class="success">Hexo `generate` command execute successfully!</div>');
      } else {
        self.append('<div class="failure">Hexo `generate` command execute failed!</div>');
      }
      self.scrollTop(self[0].scrollHeight);
    }
  });
};

AtomHexoView.prototype.deploy = function() {
  if (!this.hasParent()) {
    atom.workspaceView.prependToBottom(this);
  }

  this.html('');
  process.chdir(atom.project.getPath());

  var self = this;
  var bp = new BufferedProcess({
    command: 'hexo',
    args: ['deploy', '--generate'],
    stdout: function(output) {
      self.append('<div>' + output + '</div>');
      self.scrollTop(self[0].scrollHeight);
    },
    stderr: function(err) {
      self.append('<div class="warning">' + err + '</div>');
      self.scrollTop(self[0].scrollHeight);
    },
    exit: function(code) {
      if (0 === code) {
        self.append('<div class="success">Hexo `deploy` command execute successfully!</div>');
      } else {
        self.append('<div class="failure">Hexo `deploy` command execute failed!</div>');
      }
      self.scrollTop(self[0].scrollHeight);
    }
  });
};
