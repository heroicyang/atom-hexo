var AtomHexoView = require('./atom-hexo-view');

module.exports = {
  atomHexoView: null,
  activate: function(state) {
    this.atomHexoView = new AtomHexoView(state.atomHexoViewState);
  },
  deactivate: function() {
    this.atomHexoView.destroy();
  },
  serialize: function() {
    return {
      atomHexoViewState: this.atomHexoView.serialize()
    };
  }
};
