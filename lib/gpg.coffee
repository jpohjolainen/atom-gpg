_ = require 'underscore-plus'
fs = require 'fs'
{BufferedProcess} = require 'atom'

gpgCommand = ({args, options, stdout, stderr, exit, data}={}) ->
  options ?= {}
  options.stdio ?= ['pipe', null, null]

  stdout ?= (data) -> console.log data?.toString()

  stderr ?= (data) ->
    errorText = data.toString()
    console.log errorText

  exit ?= (code) -> console.log "exited: " + code

  args.push '--armor'
  args.push '--batch'
  args.push '--no-tty'
  args.push '--trust-model'
  args.push 'always'

  command = atom.config.get 'atom-gpg.gpgExecutable'
  command ?= 'gpg'

  # console.log 'gpg ' + args.join(' ')
  bp = new BufferedProcess
    command: command
    args: args
    options: options
    stdout: stdout
    stderr: stderr
    exit: exit

  bp.process.stdin.on 'error', (error) =>
    return if error.code == 'EPIPE'
    console.error error.message

  bp.process.on 'error', (error) =>
    if error.code == 'ENOENT'
      msg = "Error executing '#{error.path}', check settings!"
    else
      msg = error.message
    console.log msg

  bp.process.stdin?.write(data)
  bp.process.stdin?.end()


gpgEncrypt = (text, index, callback, exit_cb) ->
  stdout = (data) ->
    callback index, data

  args = []
  gpgHomeDir = atom.config.get 'atom-gpg.gpgHomeDir'
  gpgRecipients = atom.config.get 'atom-gpg.gpgRecipients'
  gpgRecipientsFile = atom.config.get 'atom-gpg.gpgRecipientsFile'
  gpgRecipientsFile ?= 'gpg.recipients'

  if gpgHomeDir
    args.push '--homedir ' + gpgHomeDir

  args.push '--encrypt'

  recipients = ''
  if gpgRecipients.indexOf('/') > -1
    recipients = fs.readFileSync gpgRecipientsFile, 'utf8'
  else
    cwd = atom.project.getRepositories()?[0]?.getWorkingDirectory()
    cwd ?= atom.project.getPaths()?[0]
    recipientsFile = cwd + '/' + gpgRecipientsFile

    try recipients = fs.readFileSync recipientsFile, 'utf8'
    catch ENOENT
      () ->

  gpgRecipients += ',' + recipients.replace /\n/g, ','

  if gpgRecipients
    recipients = gpgRecipients.split(',')
    _.map recipients, (r) ->
      args.push '-r ' + r if r

  gpgCommand
    args: args
    stdout: stdout
    data: text
    exit: exit_cb

gpgDecrypt = (text, index, callback, exit_cb) ->
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
    data: text
    exit: exit_cb

module.exports.encrypt = gpgEncrypt
module.exports.decrypt = gpgDecrypt
