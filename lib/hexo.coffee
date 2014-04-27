path = require 'path'
fs = require 'fs-plus'
Command = require './command'
ConsoleView = require './console-view'
PostCreateView = require './post-create-view'
DraftListView = require './draft-list-view'

module.exports =
  activate: ->
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
      if @checkHexoPath()
        @draftListView?.detach()
        @draftListView = new DraftListView()

    atom.workspaceView.command 'atom-hexo:publish', =>
      if @checkHexoPath()
        draftFilePath = atom.workspace.getActiveEditor().getPath()
        if draftFilePath
          draftFileName = path.basename draftFilePath, path.extname(draftFilePath)

          if fs.existsSync path.join 'source/_drafts/', path.basename(draftFilePath)
            @execCommand 'publish', [draftFileName]
          else
            @consoleView.warn 'Warning: The article has been published.'

    atom.workspaceView.on 'core:cancel core:close', =>
      return if @command.processing()

      @postCreateView?.detach()
      @draftListView?.detach()
      @consoleView?.detach()

  handleCommandEvents: ->
    atom.workspaceView.on 'hexo:exec-command', (event, {cmd, args}) =>
      @execCommand cmd, args

    atom.workspaceView.on 'hexo:before-command', (event, cmd) =>
      @currentCommand = cmd
      @consoleView.clear()

      if cmd isnt 'new'
        @consoleView.highlight "Running Hexo \"#{cmd}\" command..."
      
      @watch()

    atom.workspaceView.on 'hexo:command-stdout', (event, stdout) =>
      if @currentCommand isnt 'new'
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
    if @checkHexoPath()
      @postCreateView?.detach()
      @consoleView?.detach()
      @postCreateView = new PostCreateView({layout})

  execCommand: (cmd, args) ->
    if @checkHexoPath()
      @command.exec cmd, args

  checkHexoPath: ->
    projectPath = atom.project.getPath() or ''
    hexoConfigPath = path.join projectPath, '_config.yml'
    return true if fs.existsSync hexoConfigPath

    @consoleView.clear()
    @consoleView.warn 'Warning: Please open your Hexo folder as the root project.'
    false

  watch: () ->
    if @currentCommand is 'new'
      paths = ['/source', '/source/_posts', '/source/_drafts']
    else if @currentCommand is 'publish'
      paths = ['/source/_posts']
    return unless paths

    self = this
    @watchers = paths.map (postPath) ->
      watchPath = path.join atom.project.getPath(), postPath
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