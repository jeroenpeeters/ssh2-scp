fs      = require 'fs'
ssh2    = require 'ssh2'
scp     = require '../lib/scp'

new (ssh2.Server)({ privateKey: fs.readFileSync('./id_rsa') }, (client) ->
  console.log 'Client connected!'
  client.on('authentication', (ctx) ->
    ctx.accept()
  ).on('ready', ->
    console.log 'Client authenticated!'
    client.on 'session', (accept, reject) ->
      session = accept()
      session.once 'exec', scp (transfer) ->
        transfer.on 'done', ->
          console.log 'scp exited'
        transfer.on 'file', (path, name, data) ->
          console.log 'file', path, name, data
        transfer.on 'getfile', (path, cb) ->
          cb 'Dit is een testje'
      # session.once 'exec', (accept, reject, info) ->
      #   if scp.isScp info
      #     scp accept, reject, info
      #   else
      #     console.log 'exec is not scp', info
  ).on 'end', ->
    console.log 'Client disconnected'
).listen 2222, '127.0.0.1', ->
  console.log 'Listening on port ' + @address().port
