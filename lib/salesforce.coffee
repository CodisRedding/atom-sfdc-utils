{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'

# [Salesforce]
# Base class for all Salesforce utilities
module.exports =
class Salesforce
  constructor: (@logView, @statusBar) ->
    @utils ?= require './utils'
    @config ?= require './config/salesforce'
    # This is to allow jsforce to run without
    # warnings that use of eval is evil
    allowUnsafeNewFunction ->
      @jsforce ?= require 'jsforce'
