var NewPostView = require('./new-post-view');

module.exports = {
  activate: function(state) {
    state = state || {};
    this.newPostViewState = state.newPostViewState;

    var self = this;
    atom.workspaceView.command('atom-hexo:new-post', function() {
      self.createNewPostView();
      self.newPostView.showNewPostEditor();
    });

    atom.workspaceView.command('atom-hexo:new-page', function() {
      self.createNewPostView({
        layout: 'page'
      });
      self.newPostView.showNewPostEditor();
    });

    atom.workspaceView.command('atom-hexo:new-draft', function() {
      self.createNewPostView({
        layout: 'draft'
      });
      self.newPostView.showNewPostEditor();
    });
  },
  createNewPostView: function(options) {
    options = options || {};
    var layout = options.layout || 'post';

    if (!this.newPostView) {
      this.newPostView = new NewPostView({
        serializeState: this.newPostViewState,
        layout: layout
      });
    } else {
      this.newPostView.updatePostLayout(layout);
    }

    return this.newPostView;
  },
  deactivate: function() {
    if (this.newPostView) {
      this.newPostView.destroy();
    }
  },
  serialize: function() {
    var newPostViewState;
    return {
      newPostViewState: (newPostViewState = (
          this.newPostView ? this.newPostView.serialize() : null
        )) ? newPostViewState : this.newPostViewState
    };
  }
};