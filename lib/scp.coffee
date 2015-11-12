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
  ->
    remainingBytes = size - bytesCopied
    bytesToCopy = if remainingBytes <= @data.length then remainingBytes else @data.length
    @data.copy buffer, bytesCopied, 0, bytesToCopy
    bytesCopied += bytesToCopy
    if bytesCopied >= size
      @emitter.emit 'file', @filePath, filename, buffer
      sendOkMessage @stream
      #console.log buffer.toString('ascii')
      null

transferProcessor = ->
  match = @data.toString().match /^([C|D])([0-9]{4}) ([0-9]+) (.+)\n$/
  [type, mode, size, filename] = match[1..]
  console.log type, mode, size, filename
  sendOkMessage @stream
  acceptFile mode, (parseInt size), filename

requestProcessor = ->
  console.log @data
  @stream.write 'C0775 3 name\n'
  ->
    console.log 'y', @data
    #sendOkMessage @stream
    @stream.write 'aij'
    sendOkMessage @stream
    ->
      console.log 'x',@data
      null
  ###
  ->
    console.log 'data', @data.toString()
    console.log 'processor'
    @stream.write 'hoi'
    @stream.write new Buffer('\x01', 'binary')
    -> console.log 'data2', @data.toString()
  ###

scpCmdProcessor = (cmd) ->
  if match = cmd.match /^scp -t (.+)$/
    console.log 'file transfer'
    [ transferProcessor, match[1] ]
  else if match = cmd.match /^scp -f (.+)$/
    console.log 'file request'
    [ requestProcessor, match[1] ]

scp = (installListeners) ->
  emitter = new EventEmitter()
  installListeners emitter
  (accept, reject, info) ->
    if not scp.isScp info then return reject()
    console.log 'Client wants to execute scp: ', info
    stream = accept()
    [processor, filePath] = scpCmdProcessor info.command
    stream.on 'data', (data) ->
      if processor
        p = processor.bind(emitter:emitter, data: data, stream: stream, filePath: filePath)()
        processor = p if typeof p == 'function' or p == null

        if processor == null
          #nothing to process, close the connection
          stream.exit 0
          stream.end()
          emitter.emit 'done'
      else
        console.log 'no processor, but data is received', data.toString()

    stream.on 'error', (err) -> console.log 'err', err
    #sendOkMessage stream

scp.isScp = (info) -> info?.command?.match /^scp/

module.exports = scp
