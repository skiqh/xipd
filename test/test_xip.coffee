xip = require ".."
{exec} = require "child_process"

createServer = (callback) ->
  server = xip.createServer "xip.io", "1.2.3.4"
  server.bind 0
  {port} = server.address()
  callback port, (done) ->
    server.close()
    done()

dig = (port, type, hostname, callback) ->
  exec "dig @0.0.0.0 -p #{port} #{type} #{hostname}", (err, stdout, stderr) ->
    callback stdout

digShort = (port, type, hostname, callback) ->
  exec "dig +short @0.0.0.0 -p #{port} #{type} #{hostname}", (err, stdout, stderr) ->
    result = stdout.split("\n")[0] unless err
    callback result

module.exports =
  "encoding is unique": (test) ->
    test.expect 3
    test.equal xip.encode("10.0.0.1"), xip.encode("10.0.0.1")
    test.notEqual xip.encode("10.0.0.1"), xip.encode("10.0.0.2")
    test.notEqual xip.encode("10.0.0.1"), xip.encode("192.168.0.1")
    test.done()

  "xip.io": (test) ->
    test.expect 1
    createServer (port, done) ->
      digShort port, "A", "xip.io", (result) ->
        test.equal "1.2.3.4", result
        done test.done

  "ns-1.xip.io": (test) ->
    test.expect 1
    createServer (port, done) ->
      digShort port, "A", "ns-1.xip.io", (result) ->
        test.equal "1.2.3.4", result
        done test.done

  "NS query": (test) ->
    test.expect 1
    createServer (port, done) ->
      dig port, "NS", "xip.io", (result) ->
        test.ok result.match /xip\.io\.\s+600\s+IN\s+SOA\s+ns-1\.xip\.io\.\s+hostmaster\.xip\.io\.\s+\d+\s+28800\s+7200\s+604800\s+3600/
        done test.done

  "encoded": (test) ->
    test.expect 1
    createServer (port, done) ->
      address = "10.0.0.1"
      hostname = "#{xip.encode address}.xip.io"
      digShort port, "A", hostname, (result) ->
        test.equal address, result
        done test.done

  "lookup": (test) ->
    test.expect 1
    createServer (port, done) ->
      address = "10.0.0.2"
      hostname = "#{address}.xip.io."
      digShort port, "A", hostname, (result) ->
        test.equal address, result
        done test.done

  "encoded subdomain": (test) ->
    test.expect 1
    createServer (port, done) ->
      address = "10.0.0.3"
      hostname = "foo.#{xip.encode address}.xip.io"
      digShort port, "A", hostname, (result) ->
        test.equal address, result
        done test.done

  "subdomain lookup": (test) ->
    test.expect 1
    createServer (port, done) ->
      address = "10.0.0.4"
      hostname = "foo.#{address}.xip.io"
      digShort port, "A", hostname, (result) ->
        test.equal address, result
        done test.done

