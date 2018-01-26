# Report Artillery results to Datadog
#
# License: Apache-2.0
"use strict"
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
    percentage = (metrics['response.2xx'][0] + metrics['response.3xx'][0]) \
     * 100 / metrics['requests.completed'][0]
    return 0 if isNaN(percentage)
    Math.round(percentage*100)/100

  # This runs on artillery 'stats' event, when load test results are available.
  # It can be run 1...n times. Upon running, extract metrics, format them and
  # add to Datadog queue (but do not send them yet).
  addStats: (statsObject) =>

    stats = statsObject.report()

    metrics =
      'scenarios.created': [stats.scenariosCreated, datadog.increment]
      'scenarios.completed': [stats.scenariosCompleted, datadog.increment]
      'requests.completed': [stats.requestsCompleted, datadog.increment]
      'requests.pending': [stats.pendingRequests, datadog.increment]
      'response.2xx': [0, datadog.increment]
      'response.3xx': [0, datadog.increment]
      'response.4xx': [0, datadog.increment]
      'response.5xx': [0, datadog.increment]
      'rps.mean': [stats.rps.mean, datadog.gauge]

    for code, count of stats.codes
      metrics["response.#{code[0]}xx"][0] += count
      metrics["response.#{code}"] = [count, datadog.increment]

    for type, value of stats.latency
      metrics["latency.#{type}"] = [value, datadog.gauge]

    for type, value of stats.scenarioDuration
      metrics["scenarioDuration.#{type}"] = [value, datadog.gauge]

    metrics['response.ok_pct'] = [@getOkPercentage(metrics), datadog.gauge]

    tags = @getTags()
    for name, value of metrics
      value[1](name, value[0], tags)


  flushStats: (statsObject) ->
    datadog.flush ->
      debug 'Flushed metrics to Datadog'
    , ->
      debug 'Unable to send metrics to Datadog!'

module.exports = DatadogPlugin
