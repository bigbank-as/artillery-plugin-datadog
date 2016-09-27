# artillery-plugin-datadog

[![NPM Version][npm-image]][npm-url]
[![Build Status][travis-image]][travis-url]
[![Downloads Stats][npm-downloads]][npm-url]

[Artillery](http://artillery.io) plugin that reports load test results to [Datadog](datadoghq.com).

## Usage

- Install this plugin (`npm install artillery-plugin-datadog`)
- Create a configuration file for Artillery. Specify Datadog as the plugin to use.

```yaml
# skynet.yaml
config:
  target: https://skynet.org
  phases:
    - duration: 3
      arrivalRate: 15
      name: "First stage"
  plugins:
    datadog:
      host: artyllery.local
      tags:
        - 'mode:test'
scenarios:
  - flow:
      - get:
          url: /status

```

Run artillery and specify Datadog API key as an environment variable.

```bash
$ DATADOG_API_KEY=xxxxxxxxxxxx artillery run skynet.yaml
```

## Metrics

The following metrics are collected from Artillery and sent to Datadog.

- **artillery.scenarios.created**
- **artillery.scenarios.completed**: 
- **artillery.requests.completed**: stats.requestsCompleted
- **artillery.response.2xx**: Aggregate count of all responses whose HTTP code was in the `2xx` range
- **artillery.response.3xx**: 
- **artillery.response.4xx**: 
- **artillery.response.5xx**: 
- **artillery.response.200**: Count of responses whose HTTP code was `200` (exactly). Similarly named metric is repeated for each response status code
- **artillery.response.ok_pct**: Percentage (in the range `0 - 100`) of responses that returned with a `2xx` or `3xx` status code

## Development

Artillery plugin system documentation is at [github.com/shoreditch-ops/artillery](https://github.com/shoreditch-ops/artillery/blob/master/docs/plugins.md).

# License

[Apache-2.0 license](LICENSE.txt)

[npm-image]: https://img.shields.io/npm/v/artillery-plugin-datadog.svg?style=flat-square
[npm-url]: https://npmjs.org/package/artillery-plugin-datadog
[npm-downloads]: https://img.shields.io/npm/dm/artillery-plugin-datadog.svg?style=flat-square
[travis-image]: https://img.shields.io/travis/bigbank-as/artillery-plugin-datadog/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/bigbank-as/artillery-plugin-datadog
