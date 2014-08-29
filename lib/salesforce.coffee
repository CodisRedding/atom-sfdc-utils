{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'

module.exports =
class Salesforce
  constructor: (@logView, @statusBar) ->
    @utils ?= require './utils'
    @config ?= require './config/salesforce'
    allowUnsafeNewFunction ->
      @jsforce ?= require 'jsforce'
