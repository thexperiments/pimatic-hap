grunt = require 'grunt'
assert = require 'assert'
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
    error: (stmt) ->
      grunt.log.writeln stmt
SwitchAccessory = require("../accessories/switch")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestSwitch extends require('events').EventEmitter
  id: "testswitch-id"
  name: "testswitch"
  config: {}
  _state: null

  getState: -> Promise.resolve(@_state)

  turnOn: ->
    @_state = on
    return Promise.resolve()

  turnOff: ->
    @_state = off
    return Promise.resolve()

  fireChange: (state) ->
    @emit 'state', state

class TestAccessory extends SwitchAccessory

  getDefaultService: ->
    return Service.Switch

  toggle: (state) ->
    @getService(Service.Switch)
      .setCharacteristic(Characteristic.On, state)

describe "switch", ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestSwitch()
    accessory = new TestAccessory(device)

  describe "changing Characteristic.On", ->

    it "should turn device on if set to true", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is on
        done()
      accessory.toggle(true)

    it "should turn device off if set to false", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is off
        done()
      accessory.toggle(false)

    it "should not turn device on again after being turned on", (done) ->
      accessory.queue.onComplete = () ->
        done()
      accessory._state = true
      device.turnOn = () ->
        return Promise.resolve().then(() -> assert false)
      accessory.toggle(true)

    it "should return state when get event is fired", (done) ->
      accessory.queue.onComplete = () ->
        done()
      assertState = (state) =>
        accessory.toggle(state)
        accessory.queue.addNow(() ->
          accessory.getService(Service.Switch)
            .getCharacteristic(Characteristic.On)
            .getValue((error, value) ->
              assert error is null
              assert value is state
            )
        )
      assertState(true)
      assertState(false)

    it "should handle state event and set Characteristic.On", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is on
        done()
      device.fireChange(on)

    it "should handle setting value from 0 to 1", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is on
        done()
      accessory._state = false
      accessory.toggle(1)

    it "should handle setting value from 1 to 1", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is null
        done()
      accessory._state = true
      accessory.toggle(1)

    it "should handle setting value from 1 to 0", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is off
        done()
      accessory._state = true
      accessory.toggle(0)

    it "should handle setting value from 0 to 0", (done) ->
      accessory.queue.onComplete = () ->
        assert device._state is null
        done()
      accessory._state = false
      accessory.toggle(0)
