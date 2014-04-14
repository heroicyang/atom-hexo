path = require 'path'
{BufferedProcess} = require 'atom'
fs = require 'fs-plus'
PostFormView = require './post-form-view'
ResultsView = require './results-view'
DraftPublishView = require './draft-publish-view'

projectPathError = 
  message: 'Warning: Please open your Hexo folder as the root project.'
  className: 'warning'

module.exports =
  activate: ({@postFormViewState, @resultsViewState} = {}) ->
    @postFormView = new PostFormView(@postFormViewState)
    @resultsView = new ResultsView(@resultsViewState)

    atom.workspaceView.on 'atom-hexo:generate', =>
      @executeCommand 'generate'

    atom.workspaceView.on 'atom-hexo:deploy', =>
      @executeCommand 'deploy'

    atom.workspaceView.on 'atom-hexo:clean', =>
      @executeCommand 'clean'

    atom.workspaceView.on 'atom-hexo:publish', =>
      hexoPath = atom.project.getPath()
      unless hexoPath
        return @display projectPathError

      fs.list path.join(hexoPath, '/source/_drafts'), (err, paths) =>
        if err
          return @display message: err.message, className: 'stderr'

        paths = fs.filterExtensions paths, ['md', 'markdown']
        unless paths.length
          return @display message: 'There is no draft.', className: 'stdout'

        @createDraftPublishView().setItems paths
        @draftPublishView.toggle()

    atom.workspaceView.on 'hexo:exec', (event, {cmd, extraArgs} = {}) =>
      @executeCommand cmd, extraArgs

    atom.workspaceView.on 'hexo:show-results', (event, {message, className} = {}) =>
      @display {message, className}

    atom.workspaceView.on 'hexo:hide-results', =>
      @resultsView?.clear()
      @resultsView?.detach()

    atom.workspaceView.on 'core:cancel core:close', =>
      @postFormView?.detach()
      @resultsView?.detach()

  executeCommand: (cmd, extraArgs = []) ->
    return if not cmd or @processing()

    @resultsView?.clear()
    @display message: "Running Hexo \"#{cmd}\" command...", className: 'light'

    hexoPath = atom.project.getPath()
    if not hexoPath
      @hasWarning = true
      return @display projectPathError

    argsHash =
      generate: ['generate']
      deploy: ['generate', '--deploy']
      clean: ['clean']
      publish: ['publish']

    command = 'hexo'
    args = argsHash[cmd].concat extraArgs
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @displayOutput(output)

    stderr = (stderr) =>
      @displayError stderr
    
    exit = (code) =>
      @processExit code, cmd

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  displayOutput: (output) ->
    if -1 != output.indexOf 'Usage'
      @hasWarning = true
      return @display projectPathError

    @display message: output, className: 'stdout'

  displayError: (stderr) ->
    @hasError = true
    # fix output when deploy to github
    if /(:|\/)([^\/]+)\/([^\/]+)\.git\/?/.test(stderr) or /([\d\w]+)..(\d\w+)/.test(stderr)
      @hasError = false
      @display message: stderr, className: 'stdout'
    else
      @display message: stderr, className: 'stderr'

  processExit: (code, cmd) ->
    if code is 0
      if @hasError
        @display message: 'Error: For details, please see the log.', className: 'stderr'
      else if @hasWarning
        @display message: 'Aborted due to warnings.', className: 'stderr'
      else
        @display message: "Done, Hexo \"#{cmd}\" command executed successfully.", className: 'success'
    else
      @display message: 'Oops...Seems wrong somewhere!', className: 'stderr'

    @hasWarning = @hasError = false

    @stop()

  processing: ->
    @bufferedProcess? and @bufferedProcess.process?

  stop: ->
    if @bufferedProcess? and @bufferedProcess.process?
      @bufferedProcess.kill()

  display: ({message, className} = {}) ->
    return unless message
    message = message.replace /(\[\d+m)/g, ''

    setTimeout =>
      @resultsView?.attach()
      @resultsView?.display {message, className}
    , 0

  createDraftPublishView: ->
    unless @draftPublishView?
      @draftPublishView = new DraftPublishView()
    @draftPublishView

  deactivate: ->
    @postFormView?.detach()
    @resultsView?.detach()

  serialize: ->
    postFormViewState: @postFormView?.serialize() ? @postFormViewState
    resultsViewState: @resultsView?.serialize() ? @resultsViewState