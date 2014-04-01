{BufferedProcess} = require 'atom'
PostFormView = require './post-form-view'
ResultsView = require './results-view'

module.exports =
  activate: ({@postFormViewState, @resultsViewState} = {}) ->
    @postFormView = new PostFormView(@postFormViewState)
    @resultsView = new ResultsView(@resultsViewState)

    atom.workspaceView.on 'atom-hexo:generate', =>
      @resultsView?.clear()
      @generate() unless @processing()

    atom.workspaceView.on 'atom-hexo:deploy', =>
      @resultsView?.clear()
      @deploy() unless @processing()

    atom.workspaceView.on 'hexo:show-results', (event, data) =>
      @display data.message, data.className

    atom.workspaceView.on 'hexo:hide-results', =>
      @resultsView?.clear()
      @resultsView?.detach()

    atom.workspaceView.on 'core:cancel core:close', =>
      @postFormView?.detach()
      @resultsView?.detach()

  generate: ->
    command = 'hexo'
    args = ['generate']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @displayOutput(output)

    stderr = (stderr) =>
      @displayError stderr
    
    exit = (code) =>
      @processExit code, 'generate'

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  deploy: ->
    command = 'hexo'
    args = ['generate', '--deploy']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      @displayOutput(output)

    stderr = (stderr) =>
      @displayError stderr
    
    exit = (code) =>
      @processExit code, 'deploy'

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  displayOutput: (output) ->
    if -1 != output.indexOf 'Usage'
      @hasWarning = true
      className = 'warning'
      message = 'Please open your Hexo folder as the root project!'
    else
      className = 'stdout'
      message = output

    @display message, className

  displayError: (stderr) ->
    @hasError = true
    # fix output when deploy to github
    if /(:|\/)([^\/]+)\/([^\/]+)\.git\/?/.test(stderr) or /([\d\w]+)..(\d\w+)/.test(stderr)
      @hasError = false
      @display stderr, 'stdout'
    else
      @display stderr, 'stderr'

  processExit: (code, cmd) ->
    if code is 0
      if @hasError
        @display 'Error!!! For details, please see the log!', 'stderr'
      else if not @hasWarning
        @display "Done, Hexo `#{cmd}` command executed successfully!", 'success'
    else
      @display 'Oops...Seems wrong somewhere!', 'stderr'

    @hasWarning = @hasError = false

    @stop()

  processing: ->
    @bufferedProcess? and @bufferedProcess.process?

  stop: ->
    if @bufferedProcess? and @bufferedProcess.process?
      @bufferedProcess.kill()

  display: (message, className) ->
    return unless message
    message = message.replace /(\[\d+m)/g, ''

    setTimeout =>
      @resultsView?.attach()
      @resultsView?.display message, className
    , 0

  deactivate: ->
    @postFormView?.detach()
    @resultsView?.detach()

  serialize: ->
    postFormViewState: @postFormView?.serialize() ? @postFormViewState
    resultsViewState: @resultsView?.serialize() ? @resultsViewState