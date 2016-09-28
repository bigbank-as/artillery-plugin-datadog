# Report Artillery results to Datadog
#
# License: Apache-2.0

datadog = require 'datadog-metrics'
debug = require('debug')('plugin:datadog')

class DatadogPlugin

  constructor: (@config, @ee) ->

    debug 'Initializing Datadog...'
    datadog.init @getDatadogConfig()

    # Set event handlers
    debug 'Binding event handlers...'
    @ee.on 'stats', @addStats
    @ee.on 'done', @flushStats

  getDatadogConfig: ->
    flushIntervalSeconds: 0
    host: @config.plugins.datadog.host || ''
    prefix: @config.plugins.datadog.prefix || 'artillery.'

  # Return a list of Datadog tags for all metrics
  # Example: ['target: google.com', 'team:sre']
  getTags: ->
    tags = [
      "target:#{@config.target}"
    ]
    tags.concat @config.plugins.datadog.tags

  # Calculate the % value of successful vs failed responses
  # The lower the return value, the more requests failed (HTTP 5xx)
  # Treat redirects as OK
  getOkPercentage: (metrics) ->
    percentage = (metrics['response.2xx'] + metrics['response.3xx']) * 100 \
     / metrics['scenarios.completed']
    return 0 if isNaN(percentage)
    Math.round(percentage*100)/100

  # This runs on artillery 'stats' event, when load test results are available.
  # It can be run 1...n times. Upon running, extract metrics, format them and
  # add to Datadog queue (but do not send them yet).
  addStats: (statsObject) =>

    stats = statsObject.report()

    metrics =
      'scenarios.created': stats.scenariosCreated
      'scenarios.completed': stats.scenariosCompleted
      'requests.completed': stats.requestsCompleted
      'response.2xx': 0
      'response.3xx': 0
      'response.4xx': 0
      'response.5xx': 0

    for code, count of stats.codes
      metrics["response.#{code[0]}xx"] += count
      metrics["response.#{code}"] = count

    metrics['response.ok_pct'] = @getOkPercentage metrics

    tags = @getTags()
    for name, value of metrics
      datadog.gauge name, value, tags

  flushStats: (statsObject) ->
    datadog.flush ->
      debug 'Flushed metrics to Datadog'
    , ->
      debug 'Unable to send metrics to Datadog!'

module.exports = DatadogPlugin
