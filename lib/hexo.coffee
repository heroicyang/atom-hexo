path = require 'path'
fs = require 'fs-plus'
Command = require './command'
ConsoleView = require './console-view'
PostCreateView = require './post-create-view'
DraftPublishView = require './draft-publish-view'

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

    atom.workspaceView.command 'atom-hexo:publish', =>
      @draftPublishView?.detach()
      @draftPublishView = new DraftPublishView()

    atom.workspaceView.on 'core:cancel core:close', =>
      return if @command.processing()

      @postCreateView?.detach()
      @draftPublishView?.detach()
      @consoleView?.detach()

  handleCommandEvents: ->
    atom.workspaceView.on 'hexo:before-command', (event, cmd) =>
      @consoleView.clear()

      if cmd is 'new'
        @disableLog = true
      else
        @disableLog = false
        @log message: "Running Hexo \"#{cmd}\" command...", className: 'light'

      if cmd is 'new' or 'publish'
        @watch()

    atom.workspaceView.on 'hexo:after-command', (event, cmd) =>
      if cmd is 'new' or 'publish'
        @closeWatchers()

      if cmd is 'new'
        @postCreateView.detach()

    atom.workspaceView.on 'hexo:command', (event, {cmd, args}) =>
      @execCommand cmd, args

    atom.workspaceView.on 'hexo:command-stdout', (event, stdout) =>
      if -1 isnt stdout.indexOf 'Usage'
        @hasWarning = true
        return @showProjectPathError()

      @log message: stdout, className: 'stdout'

    atom.workspaceView.on 'hexo:command-stderr', (event, stderr) =>
      @hasError = true
      # fix output when deploy to github
      if /(:|\/)([^\/]+)\/([^\/]+)\.git\/?/.test(stderr) or /([\d\w]+)\.\.([\d\w+])/.test(stderr)
        @hasError = false
        @log message: stderr, className: 'stdout'
      else
        @log message: stderr, className: 'stderr'

    atom.workspaceView.on 'hexo:command-exit', (event, {cmd, exitCode}) =>
      if exitCode is 0
        if @hasError
          @log message: 'Error: For details, please see the log.', className: 'stderr'
        else if @hasWarning
          @log message: 'Aborted due to warnings.', className: 'stderr'
        else
          @log message: "Done, Hexo \"#{cmd}\" command executed successfully.", className: 'success'
      else
        @log message: 'Oops...Seems wrong somewhere!', className: 'stderr'

      @hasWarning = @hasError = false

  showProjectPathError: ->
    projectPathError = 
      message: 'Warning: Please open your Hexo folder as the root project.'
      className: 'warning'

    @consoleView.display projectPathError

  log: ({message, className}) ->
    return if @disableLog
    @consoleView.display {message, className}

  createPostCreateView: (layout = 'post') ->
    @postCreateView?.detach()
    @consoleView?.detach()
    @postCreateView = new PostCreateView({layout})

  execCommand: (cmd, args) ->
    unless @hexoPath
      @consoleView.clear()
      return @showProjectPathError()

    @command.exec cmd, args

  watch: ->
    hexoPath = @hexoPath
    paths = ['/source', '/source/_posts', '/source/_drafts']
    @watchers = paths.map (postPath) ->
      watchPath = path.join(hexoPath, postPath)
      return unless fs.existsSync watchPath

      fs.watch watchPath, (event, filename) ->
        return unless event is 'rename'

        filepath = path.join watchPath, filename
        # create post with page layout
        if fs.isDirectorySync filepath
          filepath = path.join filepath, '/index.md'

        atom.workspaceView.open(filepath)

  closeWatchers: ->
    while @watchers.length
      @watchers.shift()?.close()

  deactivate: ->
    @consoleView?.detach()
    @command = null
    @postCreateView?.detach()
    @draftPublishView?.detach()
    @hasWarning = @hasError = false
    @disableLog = false