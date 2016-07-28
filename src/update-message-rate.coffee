_    = require 'lodash'
http = require 'http'

class UpdateMessageRate
  constructor: (options={}) ->
    {@cache, @Date} = options
    @Date ?= Date

  _doCallback: (request, code, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
    callback null, response

  do: (request, callback) =>
    {uuid} = request.metadata
    minuteKey = @getMinuteKey()
    @cache.multi()
      .hincrby minuteKey, uuid, 1
      .expire minuteKey, 60*5
      .exec =>
        @_doCallback request, 204, callback

  getMinuteKey: ()=>
    time = @Date.now()
    @startMinute = Math.floor(time / (1000*60))
    return "message-rate:minute-#{@startMinute}"

module.exports = UpdateMessageRate
