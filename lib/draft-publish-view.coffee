path = require 'path'
{$$, SelectListView} = require 'atom'

module.exports = 
class DraftPublishView extends SelectListView
  initialize: ->
    super
    @addClass('hexo-publish-draft overlay from-top')
    @setMaxItems(10)

  viewForItem: (draftFile) ->
    "<li>#{draftFile}</li>"

  confirmed: (draftFile) ->
    return unless draftFile

    @cancel()
    draftFile = path.basename draftFile, path.extname(draftFile)
    atom.workspaceView.trigger 'hexo:exec', cmd: 'publish', extraArgs: draftFile

  setItems: (draftFilePaths) ->
    draftFilePaths = draftFilePaths.map (filepath) ->
      path.basename filepath

    super draftFilePaths

  toggle: ->
    if @hasParent()
      @cancel()
    else
      @attach()

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusFilterEditor()