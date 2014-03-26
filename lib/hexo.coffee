{BufferedProcess} = require 'atom'
PostCreateView = require './post-create-view'
ResultsView = require './results-view'

module.exports =
  activate: ({@postCreateViewState, @resultsViewState} = {}) ->
    @postCreateView = new PostCreateView(@postCreateViewState)
    @resultsView = new ResultsView(@resultsViewState)

    atom.workspaceView.on 'atom-hexo:generate', =>
      @resultsView?.clear()
      @generate() unless @processing()

    atom.workspaceView.on 'atom-hexo:deploy', =>
      @resultsView?.clear()
      @deploy() unless @processing()

    atom.workspaceView.on 'hexo:show-results', (event, data) =>
      @display data.css, data.line

    atom.workspaceView.on 'hexo:close-results', =>
      @resultsView?.clear()
      @resultsView?.detach()

    atom.workspaceView.on 'core:cancel core:close', =>
      @postCreateView?.detach()
      @resultsView?.detach()

  generate: ->
    command = 'hexo'
    args = ['generate']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      result = @filterOutput(output)
      if result
        @display result.css, result.line
      else
        @display 'stdout', output

    stderr = (stderr) =>
      @display 'stderr', stderr
    
    exit = (code) =>
      @stop()
      @display 'success', 'Hexo `generate` command execute successfully!' unless @warning

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  deploy: ->
    command = 'hexo'
    args = ['generate', '--deploy']
    options =
      cwd: atom.project.getPath()
      env: process.env

    stdout = (output) =>
      result = @filterOutput(output)
      if result
        @display result.css, result.line
      else
        @display 'stdout', output

    stderr = (stderr) =>
      @display 'stderr', stderr
    
    exit = (code) =>
      @stop()
      @display 'success', 'Hexo `deploy` command execute successfully!' unless @warning

    @bufferedProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  filterOutput: (output) ->
    if -1 != output.indexOf 'Usage'
      @warning = true
      css: 'warning'
      line: 'Please open your Hexo folder as the root project!'

  processing: ->
    @bufferedProcess? and @bufferedProcess.process?

  stop: ->
    if @bufferedProcess? and @bufferedProcess.process?
      @bufferedProcess.kill()

  display: (css, line) ->
    return unless line
    line = line.replace /(\[\d+m)/g, ''

    @resultsView?.attach()
    @resultsView?.display css, line

  deactivate: ->
    @postCreateView?.detach()
    @resultsView?.detach()

  serialize: ->
    postCreateViewState: @postCreateView?.serialize() ? @postCreateViewState
    resultsViewState: @resultsView?.serialize() ? @resultsViewState