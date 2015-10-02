_ = require 'underscore-plus'
{Point, Range} = require 'atom'
gpg = require './gpg'

module.exports =
  config:
    gpgExecutable:
      type: 'string'
      default: undefined
    gpgHomeDir:
      type: 'string'
      default: ''
    gpgRecipients:
      type: 'string'
      default: ''
    gpgRecipientsFile:
      type: 'string'
      default: undefined

  activate: ->
    console.log 'activate gpg'
    atom.commands.add 'atom-text-editor',
      'atom-gpg:encrypt-selections': => @run gpg.encrypt
      'atom-gpg:decrypt-selections': => @run gpg.decrypt

  bufferSetText: (idx, text) ->
    if @buffer[idx]
      @buffer[idx] += text
    else
      @buffer[idx] = text

  setSelections: (code) ->
    @rangeCount--

    if @rangeCount < 1
      # sort by range start point
      sorted = _.values(@ranges).sort (a, b) ->
        a.start.compare(b.start)

      # create a checkpoint so multiple changes are grouped as one rollback
      cp = @editor.getBuffer().createCheckpoint()

      # do changes in reverse order to prevent overlapping
      for point in sorted.reverse()
        i = @startPoints[point.start.toString()]
        @editor.setTextInBufferRange @ranges[i], @buffer[i]
      @editor.getBuffer().groupChangesSinceCheckpoint(cp)

  run: (func) ->
    @selectionIndex = 0
    @startPoints = {}
    @ranges = {}
    @buffer = {}

    @editor = atom.workspace.getActiveTextEditor()

    allSelectionRanges = @editor.getSelectedBufferRanges()
    @selectedRanges = _.reject allSelectionRanges, (s) -> s.start.isEqual(s.end)
    @rangeCount = @selectedRanges.length

    for range in @selectedRanges
      @ranges[@selectionIndex] = range
      @startPoints[range.start.toString()] = @selectionIndex
      text = @editor.getTextInBufferRange(range)
      bufferedRead = (idx, txt) =>
        output = txt
        @bufferSetText idx, output
      exit_cb = (code) =>
        @setSelections code

      func text, @selectionIndex, bufferedRead, exit_cb

      @selectionIndex++
