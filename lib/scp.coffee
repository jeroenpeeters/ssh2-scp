EventEmitter = require 'events'

getFilePathFromInfo = (info) ->
  [match, filename] = info?.command?.match /^scp -t (.+)$/
  filename

sendOkMessage = (stream) ->
  stream.write new Buffer('\x00', 'binary')

acceptFile = (mode, size, filename) ->
  console.log 'acceptFile', mode, size, filename
  buffer = new Buffer(size, 'binary')
  bytesCopied = 0
  (cb) ->
    remainingBytes = size - bytesCopied
    bytesToCopy = if remainingBytes <= @data.length then remainingBytes else @data.length
    @data.copy buffer, bytesCopied, 0, bytesToCopy
    bytesCopied += bytesToCopy
    if bytesCopied >= size
      @emitter.emit 'write_file', @filePath, filename, buffer
      sendOkMessage @stream
      cb null

transferProcessor = (cb) ->
  console.log @data.toString()
  match = @data.toString().match /^([C|D])([0-9]{4}) ([0-9]+) (.+)\n$/
  [type, mode, size, filename] = match[1..]
  console.log type, mode, size, filename
  sendOkMessage @stream
  cb acceptFile mode, (parseInt size), filename

requestProcessor = (cb) ->
  @emitter.emit 'read_file', @filePath, (data) =>
    @stream.write "C0775 #{data.length} name\n"
    cb ->
      # todo: assert that client sends \x00 before sending data
      @stream.write data
      sendOkMessage @stream
      cb ->
        # todo: assert that client sends \x00
        cb null

scpCmdProcessor = (cmd, stream) ->
  console.log
  if match = cmd.match /-t (.+)/
    console.log 'file transfer'
    sendOkMessage stream
    [ transferProcessor, match[1] ]
  else if match = cmd.match /-f (.+)/
    console.log 'file request'
    [ requestProcessor, match[1] ]
  else
    console.error 'Unknown scp command:', cmd

scp = (installListeners) ->
  emitter = new EventEmitter()
  installListeners emitter
  (accept, reject, info) ->
    if not scp.isScp info then return reject()
    console.log 'Client wants to execute scp: ', info
    stream = accept()
    [processor, filePath] = scpCmdProcessor info.command, stream
    stream.on 'data', (data) ->
      if processor
        processor.bind(emitter:emitter, data: data, stream: stream, filePath: filePath) (p) ->
          processor = p if typeof p == 'function' or p == null

          if processor == null
            #nothing to process, close the connection
            stream.exit 0
            stream.end()
            emitter.emit 'done'
      else
        console.warn 'no processor, but data is received', data.toString()

    stream.on 'error', (err) -> console.log 'err', err

scp.isScp = (info) -> info?.command?.match /^scp/

module.exports = scp
