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

  if gpgHomeDir
    args.push '--homedir ' + gpgHomeDir

  args.push '--encrypt'

  if gpgRecipientsFile
    recipients = fs.readFileSync gpgRecipientsFile, 'utf8'
    gpgRecipients = recipients.replace /\n/g, ','

  console.log gpgRecipients
  if gpgRecipients
    recipients = gpgRecipients.split(',')
    _.map recipients, (r) ->
      args.push '-r ' + r if r

  console.log ">>", args
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
