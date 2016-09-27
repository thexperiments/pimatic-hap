grunt = require 'grunt'
assert = require "assert"
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
    error: (stmt) ->
      grunt.log.writeln stmt
DimmerAccessory = require("../accessories/dimmer")(env)
hap = require 'hap-nodejs'
Service = hap.Service
Characteristic = hap.Characteristic

class TestDimmer extends require('events').EventEmitter
  id: "id"
  name: "test"
  config: {}
  _dimlevel: null

  changeDimlevelTo: (dimlevel) ->
    @_dimlevel = dimlevel
    @emit 'dimlevel', dimlevel
    return Promise.resolve()

class TestAccessory extends DimmerAccessory

  getDefaultService: ->
    return Service.Lightbulb

  changeBrightness: (value) ->
    @getService(Service.Lightbulb)
      .setCharacteristic(Characteristic.Brightness, value)

describe "dimmer", ->

  device = null
  accessory = null

  beforeEach ->
    device = new TestDimmer()
    accessory = new TestAccessory(device)

  describe "changing Characteristic.Brightness", ->

    it "should set dimlevel", (done) ->
      accessory.queue.onComplete = () ->
        assert device._dimlevel is 20
        done()
      accessory.changeBrightness(20)

    it "should not change dimlevel again after setting to same value", (done) ->
      accessory.queue.onComplete = () ->
        done()
      accessory._dimlevel = 5
      device.changeDimlevelTo = (dimlevel) ->
        assert false
      accessory.changeBrightness(5)

    it "should set the state of switch to on when dimlevel > 0", (done) ->
      accessory.queue.onComplete = () ->
        assert accessory._state is on
        done()
      accessory._state = off
      accessory.changeBrightness(10)

    it "should set the state of switch to off when dimlevel = 0", (done) ->
      accessory.queue.onComplete = () ->
        assert accessory._state is off
        done()
      accessory._state = on
      accessory.changeBrightness(0)
