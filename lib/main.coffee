_ = require 'underscore-plus'
{Point, Range} = require 'atom'
gpg = require './gpg'

module.exports =
  config:
    gpgExecutable:
      type: 'string'
      default: ''
    gpgHomeDir:
      type: 'string'
      default: ''
    gpgRecipients:
      type: 'string'
      default: ''
    gpgRecipientsFile:
      type: 'string'
      default: ''

  activate: ->
    console.log 'activate gpg'
    atom.commands.add 'atom-text-editor',
      'atom-gpg:encrypt-selections': => @run 'encrypt'
      'atom-gpg:decrypt-selections': => @run 'decrypt'

  bufferSetText: (idx, text) ->
    if @buffer[idx]
      @buffer[idx] += text
    else
      @buffer[idx] = text

  bufferErrors: (text) ->
    @errors += text

  indent: () ->
    allSelectionRanges = @editor.getSelectedBufferRanges()
    selectedRanges = _.reject allSelectionRanges, (s) -> s.start.isEqual(s.end)
    for range in selectedRanges
      level = @editor.indentationForBufferRow(range.start.row)
      for row in [range.start.row + 1..range.end.row]
        @editor.setIndentationForBufferRow(row, level + 1)

  setSelections: () ->
    # sort by range start point
    sorted = _.values(@ranges).sort (a, b) ->
      a.start.compare(b.start)

    # create a checkpoint so multiple changes are grouped as one rollback
    cp = @editor.getBuffer().createCheckpoint()

    # do changes in reverse order to prevent overlapping
    for point in sorted.reverse()
      i = @startPoints[point.start.toString()]

      if not @buffer[i]
        continue
      text = @buffer[i]

      if @encrypt and "source.yaml" in @rootScopes
        text = '| ' + text
      @editor.setTextInBufferRange @ranges[i], text

    if @encrypt and "source.yaml" in @rootScopes
      @indent()
    @editor.getBuffer().groupChangesSinceCheckpoint(cp)

  gpgReturn: (code) ->
    @rangeCount--

    if code != 0
      atom.notifications.addError 'GPG Error', {
        detail: @errors
        dismissable: false
      }

    # Check if all gpg executions have returned
    if @rangeCount < 1
      @setSelections()

  run: (func_name) ->
    @selectionIndex = 0
    @startPoints = {}
    @ranges = {}
    @buffer = {}
    @errors = ''
    @encrypt = (func_name == 'encrypt' ? true : false)

    @editor = atom.workspace.getActiveTextEditor()

    allSelectionRanges = @editor.getSelectedBufferRanges()
    @selectedRanges = _.reject allSelectionRanges, (s) -> s.start.isEqual(s.end)
    @rangeCount = @selectedRanges.length

    @rootScopes = @editor.getRootScopeDescriptor()?.getScopesArray()
    @rootScopes ?= @editor.getRootScopeDescriptor()

    for range in @selectedRanges
      @ranges[@selectionIndex] = range
      @startPoints[range.start.toString()] = @selectionIndex
      text = @editor.getTextInBufferRange(range)

      if not @encrypt and "source.yaml" in @rootScopes and text.startsWith('| ')
        text = text.slice(2,-1)

      bufferedRead = (idx, txt) =>
        output = txt
        @bufferSetText idx, output
      stderr_cb = (data) =>
        @bufferErrors data.toString()
      exit_cb = (code) =>
        @gpgReturn code

      if func_name == 'encrypt'
        func = gpg.encrypt
      else
        func = gpg.decrypt

      func text, @selectionIndex, bufferedRead, stderr_cb, exit_cb

      @selectionIndex++
