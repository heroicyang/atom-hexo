path = require 'path'
fs = require 'fs-plus'
Command = require './command'
ConsoleView = require './console-view'
PostCreateView = require './post-create-view'
DraftListView = require './draft-list-view'

pathWarning = 'Warning: Please open your Hexo folder as the root project.'

module.exports =
  activate: ->
    @hexoPath = atom.project.getPath()
    @consoleView = new ConsoleView()
    @command = new Command()

    @handleEvents()
    @handleCommandEvents()

  handleEvents: ->
    atom.workspaceView.command 'atom-hexo:new-post', =>
      @createPostCreateView()

    atom.workspaceView.command 'atom-hexo:new-page', =>
      @createPostCreateView('page')

    atom.workspaceView.command 'atom-hexo:new-draft', =>
      @createPostCreateView('draft')

    atom.workspaceView.command 'atom-hexo:generate', =>
      @execCommand 'generate'

    atom.workspaceView.command 'atom-hexo:deploy', =>
      @execCommand 'deploy'

    atom.workspaceView.command 'atom-hexo:clean', =>
      @execCommand 'clean'

    atom.workspaceView.command 'atom-hexo:list-drafts', =>
      if @hexoPath
        @draftListView?.detach()
        @draftListView = new DraftListView()
      else
        @consoleView.clear()
        @consoleView.warn pathWarning

    atom.workspaceView.command 'atom-hexo:publish', =>
      draftFile = atom.workspace.getActiveEditor().getPath()
      if draftFile
        draftFile = path.basename draftFile, path.extname(draftFile)
        @execCommand 'publish', [draftFile]

    atom.workspaceView.on 'core:cancel core:close', =>
      return if @command.processing()

      @postCreateView?.detach()
      @draftListView?.detach()
      @consoleView?.detach()

  handleCommandEvents: ->
    atom.workspaceView.on 'hexo:before-command', (event, cmd) =>
      @currentCommand = cmd
      @consoleView.clear()

      if cmd isnt 'new'
        @consoleView.highlight "Running Hexo \"#{cmd}\" command..."
      
      @watch()

    atom.workspaceView.on 'hexo:command', (event, {cmd, args}) =>
      @execCommand cmd, args

    atom.workspaceView.on 'hexo:command-stdout', (event, stdout) =>
      if -1 isnt stdout.indexOf 'Usage'
        @hasWarning = true
        @consoleView.warn pathWarning
      else if @currentCommand isnt 'new'
        @consoleView.info stdout

    atom.workspaceView.on 'hexo:command-stderr', (event, stderr) =>
      @hasError = true
      # fix output when deploy to github
      if /(:|\/)([^\/]+)\/([^\/]+)\.git\/?/.test(stderr) or /([\d\w]+)\.\.([\d\w+])/.test(stderr)
        @hasError = false
        @consoleView.info stderr
      else
        @consoleView.error stderr

      @removeWatchers()

    atom.workspaceView.on 'hexo:command-exit', (event, exitCode) =>
      if @currentCommand is 'new'
        @postCreateView.detach()

      if exitCode is 0
        if @hasError
          @consoleView.error 'Error: For details, please see the log.'
        else if @hasWarning
          @consoleView.error 'Aborted due to warnings.'
        else if @currentCommand isnt 'new'
          @consoleView.success "Done, Hexo \"#{@currentCommand}\" command executed successfully."
      else
        @consoleView.error 'Oops...Seems wrong somewhere!'

      @hasWarning = @hasError = false
      @currentCommand = null

  createPostCreateView: (layout = 'post') ->
    @postCreateView?.detach()
    @consoleView?.detach()
    @postCreateView = new PostCreateView({layout})

  execCommand: (cmd, args) ->
    if @hexoPath
      @command.exec cmd, args
    else
      @consoleView.clear()
      @consoleView.warn pathWarning

  watch: () ->
    if @currentCommand is 'new'
      paths = ['/source', '/source/_posts', '/source/_drafts']
    else if @currentCommand is 'publish'
      paths = ['/source/_posts']
    return unless paths

    self = this
    hexoPath = @hexoPath

    @watchers = paths.map (postPath) ->
      watchPath = path.join(hexoPath, postPath)
      return unless fs.existsSync watchPath

      do (watchPath) ->
        fs.watch watchPath, (event, filename) ->
          return unless event is 'rename' and filename.nlink isnt 0

          filepath = path.join watchPath, filename
          # create post with page layout
          if fs.isDirectorySync filepath
            filepath = path.join filepath, '/index.md'

          atom.workspaceView.open(filepath).done ->
            self.removeWatchers()

  removeWatchers: ->
    while @watchers.length
      @watchers.shift()?.close()

  deactivate: ->
    @consoleView?.detach()
    @command = null
    @postCreateView?.detach()
    @draftListView?.detach()
    @hasWarning = @hasError = false
    @currentCommand = null