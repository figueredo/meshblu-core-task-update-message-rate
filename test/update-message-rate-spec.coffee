_ = require 'lodash'
redis = require 'fakeredis'
uuid  = require 'uuid'
UpdateMessageRate = require '../'
MeshbluCoreCache = require 'meshblu-core-cache'

describe 'UpdateMessageRate', ->
  before ->
    @clientKey = uuid.v1()
    @client = redis.createClient @clientKey
    cache = new MeshbluCoreCache client: redis.createClient @clientKey
    startTime = Date.now()
    FakeDate = now: -> return startTime
    @sut = new UpdateMessageRate {cache: cache, Date: FakeDate}
    @request =
      metadata:
        responseId: 'its-electric'
        uuid: 'electric-eels'
        messageType: 'received'
        options: {}
      rawData: '{}'

  describe '->do', ->
    context 'when given a valid message', ->
      before (done) ->
        @sut.do @request, (error, @response) => done error

      it 'should return a 204', ->
        expectedResponse =
          metadata:
            responseId: 'its-electric'
            code: 204
            status: 'No Content'

        expect(@response).to.deep.equal expectedResponse

      it 'should have only one key', (done) ->
        setTimeout =>
          @client.keys '*', (error, result) ->
            expect(result.length).to.equal 1
            done()
        , 100

      it 'should add a key to redis for the correct minute', (done) ->
        setTimeout =>
          @client.exists @sut.getMinuteKey(), (error, result) ->
            expect(result).to.equal 1
            done()
        , 100

      it 'should have a value of "1" for that uuid and minute', (done) ->
        setTimeout =>
          @client.hget @sut.getMinuteKey(), 'electric-eels', (error, result) ->
            expect(result).to.equal 1
            done()
        , 100

    context 'when given another message', ->
      before (done) ->
        @sut.do @request, (error, @response) => done error

      it 'should have a value of "2" for that uuid and minute', (done) ->
        setTimeout =>
          @client.hget @sut.getMinuteKey(), 'electric-eels', (error, result) ->
            expect(result).to.equal 2
            done()
        , 100
