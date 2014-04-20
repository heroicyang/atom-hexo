{View} = require 'atom'

module.exports =
class ConsoleView extends View
  @content: ->
    @div class: 'atom-hexo hexo-console tool-panel panel-bottom', =>
      @div class: 'output padded', outlet: 'output'

  attach: ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()

  highlight: (message) ->
    className = 'highlight'
    @display {message, className}

  success: (message) ->
    className = 'success'
    @display {message, className}

  info: (message) ->
    className = 'info'
    @display {message, className}

  warn: (message) ->
    className = 'warning'
    @display {message, className}

  error: (message) ->
    className = 'error'
    @display {message, className}

  display: ({message, className}) ->
    return unless message

    @attach()

    # strip ANSI escape codes
    message = message.replace /\x1B\[([0-9]{1,2}(;[0-9]{1,2})*)?[m|K]/g, ''

    setTimeout =>
      @output.append "<pre class='line #{className}'>#{message}</pre>"
      @output.scrollTop @output[0].scrollHeight
    , 0

  clear: ->
    @output.empty() if @output.children().length