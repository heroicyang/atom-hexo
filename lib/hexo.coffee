PostCreateView = require './post-create-view'

module.exports =
  activate: ({@postCreateViewState}={}) ->
    atom.workspaceView.command 'atom-hexo:new-post', =>
      @createPostCreateView()

    atom.workspaceView.command 'atom-hexo:new-page', =>
      @createPostCreateView 'page'

    atom.workspaceView.command 'atom-hexo:new-draft', =>
      @createPostCreateView 'draft'

  createPostCreateView: (layout = 'post') ->
    if not @postCreateView
      @postCreateView = new PostCreateView(serializeState: @postCreateViewState, layout: layout)
    else
      @postCreateView.setPostLayout(layout)

    @postCreateView.showPostCreateEditor()

  deactivate: ->
    @postCreateView?.destroy()

  serialize: ->
    postCreateViewState: @postCreateView?.serialize() ? @postCreateViewState