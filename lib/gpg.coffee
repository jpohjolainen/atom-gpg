_ = require 'underscore-plus'
fs = require 'fs'
{BufferedProcess} = require 'atom'

gpgCommand = ({args, options, stdout, stderr, exit, data}={}) ->
  options ?= {}
  options.stdio ?= ['pipe', null, null]

  stderr ?= (data) ->
    errorText = data.toString()
    console.log errorText
    atom.notifications.addError 'Error', { detail: errorText, dismissable: true }

  args.push '-q'
  args.push '--armor'
  args.push '--batch'
  args.push '--no-tty'
  args.push '--trust-model'
  args.push 'always'

  command = atom.config.get 'atom-gpg.gpgExecutable'
  if not command
    command = 'gpg'

  bp = new BufferedProcess
    command: command
    args: args
    options: options
    stdout: stdout
    stderr: stderr
    exit: exit

  bp.onWillThrowError (error) =>
    if error.error.code == 'ENOENT'
      msg = "Error executing '#{error.error.path}' in path '#{process.env.PATH}', check settings!"
    else
      msg = error.error.message
    atom.notifications.addError msg
    error.handle()

  bp.process.stdin.on 'error', (error) =>
    atom.notifications.addError error.message if error.code != 'EPIPE'

  bp.process.stdin?.write(data)
  bp.process.stdin?.end()


gpgEncrypt = (text, index, callback, stderr_cb, exit_cb) ->
  stdout = (data) ->
    callback index, data

  args = []
  gpgHomeDir = atom.config.get 'atom-gpg.gpgHomeDir'
  gpgRecipients = atom.config.get 'atom-gpg.gpgRecipients'
  gpgRecipientsFile = atom.config.get 'atom-gpg.gpgRecipientsFile'
  if not gpgRecipientsFile
    gpgRecipientsFile = 'gpg.recipients'

  if gpgHomeDir
    args.push '--homedir=' + gpgHomeDir

  args.push '--encrypt'

  cwd = atom.project.getRepositories()?[0]?.getWorkingDirectory()
  cwd ?= atom.project.getPaths()?[0]
  cwd ?= atom.workspace.getActiveTextEditor()?.getBuffer().getPath()

  # add project base dir or file's current working dir to gpgRecipientsFile
  # if path is not included.
  if gpgRecipientsFile.indexOf('/') == -1
    gpgRecipientsFile = cwd + '/' + gpgRecipientsFile

  # try to read recipients file and ignore errors
  fileRecipients = ''
  try fileRecipients = fs.readFileSync gpgRecipientsFile, 'utf8'
  catch ENOENT
    () ->

  # add recipients file content to recipients string delimitered by comma
  gpgRecipients += ',' + fileRecipients.replace /\n/g, ','

  # split recipients string into array and discard empty strings
  recipients = gpgRecipients.split ','
  recipients = _.filter recipients, (r) -> r

  if recipients.length < 1
    message = 'Add recipient user ids in atom-gpg package settings'
    if cwd
      message += '\nor create \'' + cwd + '/' + gpgRecipientsFile + '\' file with one user id per line.'
    atom.notifications.addError 'No GPG recipients defined.', {
      detail: message
    }
    return false

  # create gpg arguments from recipients
  _.map recipients, (r) ->
    args.push '-r ' + r if r

  gpgCommand
    args: args
    stdout: stdout
    stderr: stderr_cb
    data: text
    exit: exit_cb

gpgDecrypt = (text, index, callback, stderr_cb, exit_cb) ->
  stdout = (data) ->
    callback index, data

  args = []
  gpgHomeDir = atom.config.get 'atom-gpg.gpgHomeDir'

  if gpgHomeDir
    args.push '--homedir ' + gpgHomeDir

  args.push '--decrypt'

  gpgCommand
    args: args
    stdout: stdout
    stderr: stderr_cb
    data: text
    exit: exit_cb

module.exports.encrypt = gpgEncrypt
module.exports.decrypt = gpgDecrypt
