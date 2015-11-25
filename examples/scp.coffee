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
        transfer.on 'write_file', (path, name, data) ->
          console.log 'impl::file', path, name, data
        transfer.on 'read_file', (path, cb) ->
          cb "You requested: #{path}"
        transfer.on 'mkdir', (mode, path) ->
          console.log 'impl::mkdir', mode, path
      # session.once 'exec', (accept, reject, info) ->
      #   if scp.isScp info
      #     scp accept, reject, info
      #   else
      #     console.log 'exec is not scp', info
  ).on 'end', ->
    console.log 'Client disconnected'
).listen 2222, '0.0.0.0', ->
  console.log 'Listening on port ' + @address().port
