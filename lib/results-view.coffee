{View} = require 'atom'

module.exports =
class ResultsView extends View
  @content: ->
    @div tabIndex: -1, class: 'atom-hexo panel tool-panel panel-bottom', =>
      @div outlet: 'resultsPanel', class: 'panel-body results-panel'

  initialize: (serializeState) ->

  attach: ->
    atom.workspaceView.prependToBottom(this) unless @hasParent()

  detach: ->
    return unless @hasParent()
    @empty()
    super()

  empty: ->
    @resultsPanel.empty() if @resultsPanel.children()

  display: (css, line) ->
    @resultsPanel.append "<pre class='line #{css}'>#{line}</pre>"
    @resultsPanel.scrollTop @resultsPanel[0].scrollHeight