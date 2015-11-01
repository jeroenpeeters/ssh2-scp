EventEmitter = require 'events'

sendOkMessage = (stream) ->
  stream.write new Buffer('\x00', 'binary')

acceptFile = (mode, size, filename) ->
  console.log 'acceptFile', mode, size, filename
  buff = new Buffer(size, 'binary')
  bytesCopied = 0
  (data, stream) ->
    remainingBytes = size - bytesCopied
    bytesToCopy = if remainingBytes <= data.length then remainingBytes else data.length
    #bytesToCopy = data.length
    #console.log data
    data.copy buff, bytesCopied, 0, bytesToCopy
    bytesCopied += bytesToCopy
    console.log bytesCopied: bytesCopied
    if bytesCopied >= size
      console.log 'transfer finished!'
      sendOkMessage stream
      console.log '-------------------------'
      console.log buff.toString('ascii')
      null

transferProcessor = (data, stream) ->
  console.log 'transferProcessor', data
  match = data.toString().match /^([C|D])([0-9]{4}) ([0-9]+) (.+)\n$/
  [type, mode, size, filename] = match[1..]
  console.log type, mode, size, filename
  sendOkMessage stream
  acceptFile mode, (parseInt size), filename

scp = (installListeners) ->
  emitter = new EventEmitter()
  installListeners emitter
  (accept, reject, info) ->
    if not scp.isScp info then return reject()
    console.log 'Client wants to execute scp: ', info
    stream = accept()
    processor = transferProcessor
    stream.on 'data', (data) ->
      if processor
        p = processor data, stream
        processor = p if typeof p == 'function' or p == null

        if processor == null
          # nothing to process, close the connection
          stream.exit 0
          stream.end()
          emitter.emit 'done'
      else
        console.log 'no processor, but data is received', data.toString()
        
    stream.on 'error', (err) -> console.log 'err', err
    sendOkMessage stream

scp.isScp = (info) -> info?.command?.match /^scp/

module.exports = scp
