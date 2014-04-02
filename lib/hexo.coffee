{BufferedProcess} = require 'atom'
PostFormView = require './post-form-view'
ResultsView = require './results-view'

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

    atom.workspaceView.on 'hexo:show-results', (event, result) =>
      @display result

    atom.workspaceView.on 'hexo:hide-results', =>
      @resultsView?.clear()
      @resultsView?.detach()

    atom.workspaceView.on 'core:cancel core:close', =>
      @postFormView?.detach()
      @resultsView?.detach()

  executeCommand: (cmd) ->
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

    command = 'hexo'
    args = argsHash[cmd]
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

  deactivate: ->
    @postFormView?.detach()
    @resultsView?.detach()

  serialize: ->
    postFormViewState: @postFormView?.serialize() ? @postFormViewState
    resultsViewState: @resultsView?.serialize() ? @resultsViewState