{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'

# [Salesforce]
# Base class for all Salesforce utilities
module.exports =
class Salesforce
  _loginUrl = atom.config.get("sfdc-utils.loginUrl")
  _username = atom.config.get("sfdc-utils.username")
  _password = atom.config.get("sfdc-utils.password")
  _securityToken = atom.config.get("sfdc-utils.securityToken")
  _apiVersion = atom.config.get("sfdc-utils.apiVersion")

  constructor: (@logView, @statusBar) ->
    @utils ?= require './utils'
    # This is to allow jsforce to run without
    # warnings that use of eval is evil
    allowUnsafeNewFunction ->
      @jsforce ?= require 'jsforce'
    @conn = new jsforce.Connection()

  getApiVersion: ->
    return _apiVersion

  login: (callback) ->
    @conn.login _username, _password + _securityToken, (err, res) ->
      callback(err, res)
