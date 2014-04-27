path = require 'path'
fs = require 'fs-plus'
{$$, SelectListView} = require 'atom'

module.exports = 
class DraftListView extends SelectListView
  initialize: ->
    super
    @addClass 'hexo-draft-list overlay from-top'
    @setMaxItems 10
    @setLoading 'Loading drafts...'
    @attach()

    hexoPath = atom.project.getPath()
    extensions = ['.markdown', '.md', '.mdown', '.mkd', '.mkdown', '.ron']
    fs.list path.join(hexoPath, '/source/_drafts'), extensions, (err, filepaths) =>
      if err
        return @setError err.message or 'Failed to load drafts!'

      if filepaths and filepaths.length
        @setItems filepaths
      else
        @setError 'There is no draft.'
      
      @setLoading ''

  viewForItem: (draftFile) ->
    $$ ->
      @li =>
        @div class: 'icon icon-file-text', draftFile

  confirmed: (draftFile) ->
    return unless draftFile

    @cancel()
    draftFile = path.join 'source/_drafts/', draftFile
    atom.workspaceView.open(draftFile)

  setItems: (draftFilePaths) ->
    draftFilePaths = draftFilePaths.map (filepath) ->
      path.basename filepath

    super draftFilePaths

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusFilterEditor()