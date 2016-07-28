_ = require 'lodash'
redis = require 'fakeredis'
uuid  = require 'uuid'
UpdateMessageRate = require '../'

describe 'UpdateMessageRate', ->
  before ->
    @clientKey = uuid.v1()
    @client = redis.createClient @clientKey
    taskCache = redis.createClient @clientKey
    startTime = Date.now()
    FakeDate = now: -> return startTime
    @sut = new UpdateMessageRate {cache: taskCache, Date: FakeDate}
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
        @client.keys '*', (error, result) ->
          expect(result.length).to.equal 1
          done()

      it 'should add a key to redis for the correct minute', (done) ->
        @client.exists @sut.getMinuteKey(), (error, result) ->
          expect(result).to.equal 1
          done()

      it 'should have a value of "1" for that uuid and minute', (done) ->
        @client.hget @sut.getMinuteKey(), 'electric-eels', (error, result) ->
          expect(result).to.equal 1
          done()

    context 'when given another message', ->
      before (done) ->
        @sut.do @request, (error, @response) => done error

      it 'should have a value of "2" for that uuid and minute', (done) ->
        @client.hget @sut.getMinuteKey(), 'electric-eels', (error, result) ->
          expect(result).to.equal 2
          done()
