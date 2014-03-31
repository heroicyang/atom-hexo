{View} = require 'atom'

module.exports =
class ResultsView extends View
  @content: ->
    @div tabIndex: -1, class: 'atom-hexo results-view tool-panel panel-bottom', =>
      @div outlet: 'contentPanel', class: 'padded content-panel'

  initialize: (serializeState) ->

  attach: ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()

  detach: ->
    return unless @hasParent()
    super()

  clear: ->
    @contentPanel.empty() if @contentPanel.children()

  display: (message, className='output') ->
    @contentPanel.append "<pre class='line #{className}'>#{message}</pre>"
    @contentPanel.scrollTop @contentPanel[0].scrollHeight