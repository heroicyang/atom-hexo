var util = require('util');
var path = require('path');
var _ = require('lodash');
var View = require('atom').View;
var EditorView = require('atom').EditorView;
var BufferedProcess = require('atom').BufferedProcess;

module.exports = NewPostView;

function NewPostView() {
  View.apply(this, arguments);
}

util.inherits(NewPostView, View);
_.extend(NewPostView, View);

NewPostView.content = function() {
  var self = this;
  this.div({
    'tabIndex': -1,
    'class': 'atom-hexo tool-panel panel-bottom'
  }, function() {
    self.div({
      'class': 'new-post-view-container block'
    }, function() {
      self.span('Post Title: ', {
        'class': 'editor-label pull-left'
      });

      self.subview('newPostEditor', new EditorView({
        mini: true
      }));
    });
  });
};

_.extend(NewPostView.prototype, {
  initialize: function(options) {
    options = options || {};
    this.layout = options.layout || 'post';
    this.handleEvents();
    this.showNewPostEditor();
  },
  showNewPostEditor: function() {
    if (!this.hasParent()) {
      atom.workspaceView.prependToBottom(this);
    }

    this.updateEditorLabel();
    this.newPostEditor.focus();
    this.newPostEditor.getEditor().selectAll();
  },
  handleEvents: function() {
    var self = this;
    this.newPostEditor.on('core:confirm', function(e) {
      self.createPost(self.newPostEditor.getText());
    });
  },
  updatePostLayout: function(layout) {
    this.layout = layout;
    this.updateEditorLabel();
  },
  updateEditorLabel: function() {
    var editorLabel = this.layout.substr(0, 1).toUpperCase() +
        this.layout.substr(1) + ' Title: ';
    this.find('.editor-label').text(editorLabel);
  },
  createPost: function(title) {
    process.chdir(atom.project.getPath());

    var self = this;
    var bp = new BufferedProcess({
      command: 'hexo',
      args: ['new', this.layout, title],
      stdout: function(output) {
        var fileUri = output.substr(output.indexOf(atom.project.getPath())).replace('\n', '');
        atom.workspaceView.open(fileUri)
          .done(function() {
            self.detach();
          });
      },
      stderr: function(err) {
        console.log(err);
      }
    });
  }
});