EventEmitter = require 'events'

getFilePathFromInfo = (info) ->
  [match, filename] = info?.command?.match /^scp -t (.+)$/
  filename

_sendOkMessage = (stream) ->
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
      if @data.length > bytesToCopy
        console.log 'there is more data to copy then we just copied!!!!'
        console.log 'DATA', @data.toString()
      @emitter.emit 'write_file', @filePath, filename, buffer
      @stream.sendOkMessage()
      #cb (cb2) ->
      #  console.log 'CB2', @data, @data.toString()
      cb transferProcessor

acceptDirectory = (mode, filename) ->




transferProcessor = (cb) ->
  console.log 'transferProcessor', @data, @data[0], @data[0] == 0, @data.toString()
  matches = @data.toString().match
  if [all, type, mode, size, filename] = @data.toString().match(/^([C|D])([0-9]{4}) ([0-9]+) (.+)\n$/) or [all, type] = @data.toString().match /^(E)\n$/
    if type == 'C'
      @stream.sendOkMessage()
      cb acceptFile mode, (parseInt size), filename
    else if type == 'D'
      #cb acceptDirectory mode, filename
      console.log 'acceptDirectory', mode, filename
      @emitter.emit 'mkdir', mode, filename
      @stream.sendOkMessage()
      cb transferProcessor
    else if type == 'E'
      @stream.sendOkMessage()
      @stream.sendOkMessage()
      cb transferProcessor
    else
      console.log 'unknown type', type
      # , =>
      #   @stream.sendOkMessage()

requestProcessor = (cb) ->
  @emitter.emit 'read_file', @filePath, (data) =>
    @stream.write "C0775 #{data.length} name\n"
    cb ->
      # todo: assert that client sends \x00 before sending data
      @stream.write data
      @stream.sendOkMessage()
      cb ->
        # todo: assert that client sends \x00
        cb null

scpCmdProcessor = (cmd, stream) ->
  console.log
  if match = cmd.match /-t (.+)/
    stream.sendOkMessage()
    [ transferProcessor, match[1] ]
  else if match = cmd.match /-f (.+)/
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
    stream.sendOkMessage = -> _sendOkMessage stream
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
