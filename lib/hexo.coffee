PostCreateView = require './post-create-view'
ConsoleView = require './console-view'

module.exports =
  activate: ({@postCreateViewState, @consoleViewState}={}) ->
    atom.workspaceView.command 'atom-hexo:new-post', =>
      @createPostCreateView()

    atom.workspaceView.command 'atom-hexo:new-page', =>
      @createPostCreateView 'page'

    atom.workspaceView.command 'atom-hexo:new-draft', =>
      @createPostCreateView 'draft'

    atom.workspaceView.command 'atom-hexo:generate', =>
      @executeConsoleCommand 'generate'

  createPostCreateView: (layout = 'post') ->
    if not @postCreateView
      @postCreateView = new PostCreateView(serializeState: @postCreateViewState, layout: layout)
    else
      @postCreateView.setPostLayout(layout)

    @postCreateView.showPostCreateEditor()

  executeConsoleCommand: (command) ->
    if not @consoleView
      @consoleView = new ConsoleView(@consoleViewState)

    if @consoleView.bufferedProcess? and @consoleView.bufferedProcess.process?
      @consoleView.display 'warning', 'Other commands are being executed!'
    else
      switch command
        when 'generate' then @consoleView.generate()

  deactivate: ->
    @postCreateView?.destroy()

  serialize: ->
    postCreateViewState: @postCreateView?.serialize() ? @postCreateViewState
    consoleViewState: @consoleView?.serialize() ? @consoleViewState