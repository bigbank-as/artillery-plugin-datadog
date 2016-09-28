chai = require 'chai'
expect = chai.expect
EventEmitter = require 'events'

# Setup
datadogPlugin = null
config =
  plugins:
    datadog:
      tags:
        - 'team:sre'
eventEmitter = new EventEmitter

# Force-reload the module before every test so we
# can realistically test all the scenarios.
beforeEach ->
  sourceFile = '../src/index.js'
  delete require.cache[require.resolve sourceFile]
  DatadogPlugin = require sourceFile
  datadogPlugin = new DatadogPlugin config, eventEmitter

describe '#getDatadogConfig', ->

  it 'should return default config when user did not override anything', ->
    expect(datadogPlugin.getDatadogConfig()).to.deep.equal
      flushIntervalSeconds: 0
      host: ''
      prefix: 'artillery.'

  it 'should use user-defined values from config', ->
    datadogPlugin.config =
      plugins:
        datadog:
          host: 'artillery.local'
          prefix: 'artillery.platoon.'

    expect(datadogPlugin.getDatadogConfig()).to.deep.equal
      flushIntervalSeconds: 0
      host: 'artillery.local'
      prefix: 'artillery.platoon.'

describe '#getTags', ->

  it 'should concat user-provided and automatically added tags', ->
    datadogPlugin.config =
      plugins:
        datadog:
          tags: ['team:sre']
      target: 'https://twitter.com/Stranger_Things'

    expect(datadogPlugin.getTags()).to.deep.equal [
      'target:https://twitter.com/Stranger_Things',
      'team:sre'
    ]

describe '#getOkPercentage', ->
  it 'should return 0 when no queries were made', ->
    metrics =
      'response.2xx': 0
      'response.3xx': 0
      'scenarios.completed': 0
    expect(datadogPlugin.getOkPercentage(metrics)).to.equal(0)

  it 'should return a correct percentage value based on response code counts', ->
    metrics =
      'response.2xx': 8
      'response.3xx': 3
      'scenarios.completed': 101
    expect(datadogPlugin.getOkPercentage(metrics)).to.be.a('Number').and.to.equal(10.89)

