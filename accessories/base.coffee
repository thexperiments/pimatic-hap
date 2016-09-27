module.exports = (env) ->

  hap = require 'hap-nodejs'
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')
  Queue = require 'bluebird-queue'

  # base class for all homekit accessories in pimatic
  class BaseAccessory extends Accessory

    supportedServiceOverrides: {
      "Lightbulb": Service.Lightbulb
    }

    hapConfig: null
    queue = null

    constructor: (device) ->
      @hapConfig = device.config.hap
      @queue = new Queue({
        # make sure that asynchronous requests are processed synchronously
        concurrency: 1,
        onError: (error) -> env.logger.error(
          device.name + ': error when working on request queue. Message: ' + error.message)
      })
      serialNumber = uuid.generate('pimatic-hap:accessories:' + device.id)
      super(device.name, serialNumber)

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber)

      @addService(Service.BridgingState)
        .getCharacteristic(Characteristic.Reachable)
        .on 'set', (value, callback) =>
          env.logger.warn 'accessory ' + device.id + ' was set to unreachable!' unless value
          callback()

      @on 'identify', (paired, callback) =>
        @identify(device, paired, callback)

    ## default identify method just calls callback
    identify: (device, paired, callback) =>
      callback()

    ## calls promise, then callback, and handles errors
    handleVoidPromise: (promise, callback) =>
      promise
        .then( => callback() )
        .catch( (error) =>
          env.logger.error "Could not call promise: " + error.message
          env.logger.debug error.stack
          callback(error)
        )
        .done()

    handleReturnPromise: (promise, callback, converter) =>
      promise
        .then( (value) =>
          if converter != null
            value = converter(value)
          callback(null, value)
        )
        .catch( (error) =>
          env.logger.error "Could not call promise: " + error.message
          env.logger.debug error.stack
          callback(error, null)
        )
        .done()

    exclude: =>
      if @hapConfig != null && @hapConfig != undefined
        return @hapConfig.exclude != null && @hapConfig.exclude
      return false

    getServiceOverride: =>
      if @hapConfig != null && @hapConfig != undefined &&
      @hapConfig.service != null && @hapConfig.service != undefined &&
      @hapConfig.service of @supportedServiceOverrides
        return @supportedServiceOverrides[@hapConfig.service]
      return @getDefaultService()

    getDefaultService: =>
      throw new Error "getDefaultService must be overridden"
