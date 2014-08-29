module.exports =
class Utils
  @colorify: (boolValue) ->
    if boolValue
      return '<font color="green">true</font>'
    else
      return '<font color="red">false</font>'

  @colorify2: (val, bool = true) ->
    return "<font color='#{if bool then 'green' else 'red'}'>#{val}</font>"
