env = require './env'

module.exports =
  loginUrl: atom.config.get("sfdc-utils.loginUrl")
  username: atom.config.get("sfdc-utils.username")
  password: atom.config.get("sfdc-utils.password")
  securityToken: atom.config.get("sfdc-utils.securityToken")
  apiVersion: atom.config.get("sfdc-utils.apiVersion")
  clientId: env.SF_OAUTH2_CLIENT_ID
  clientSecret: env.SF_OAUTH2_CLIENT_SECRET
  redirectUri: env.SF_OAUTH2_REDIRECT_URI or "http://localhost:4000/oauth2/callback"
  bigTable: "BigTable__c"
  upsertTable: "UpsertTable__c"
  upsertField: "ExtId__c"
  proxyUrl: env.SF_AJAX_PROXY_URL or "http://localhost:3123/proxy"
  logLevel: env.DEBUG
