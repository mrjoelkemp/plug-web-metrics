# Plug Web Metrics

> Basic telemetry metrics for a Plug-based, Elixir backend

## Why?
I was building a Plug-powered backend service in Elixir and wanted some standard service metrics to aggregate like the number of incoming requests, number of successful/failed requests, etc. I couldn't find a Plug like that anywhere.

Plug's default telemetry events (an event on plug entry and exit) forces you to work around metadata and naming to get similar metrics.

Feel free to add additional metrics that you find helpful.

## What doesn't this do?
This module generates telemetry measurements during the lifecycle of a request. It **does not** aggregate those measurements over time.

To aggregrate measurements over time, you'd typically use TelemetryMetrics and a reporter to send these measurements to a metrics aggregator/store (like Prometheus) to do the actual aggregations over time.

## Installation

```elixir
def deps do
  [
    {:plugwebmetrics, "~> 0.1.0"}
  ]
end
```

## Usage

Use this similar to how you would use [Plug.Telemetry](https://hexdocs.pm/plug/Plug.Telemetry.html) (no event_prefix needed).

```elixir
defmodule MyRouter do
  use Plug.Router
  require Plugwebmetrics

  plug(:match)
  plug Plugwebmetrics
  plug(:dispatch)

  get("/hello", do: send_resp(conn, 200, "world"))
end
```

## Measurements tracked

### `plug.incoming_requests.count`

* Triggered on every request
* The count will always be 1. Aggregations are done outside of this plug.

### `plug.successful_requests.count`

* Triggered on a successful request (a status code < 500)
* The count will always be 1. Aggregations are done outside of this plug.

### `plug.failed_requests.count`

* Triggered on a failed request (a status code >= 500)
* The count will always be 1. Aggregations are done outside of this plug.

### `plug.response_time.duration`

* Triggered on every request.
* The time is took for you to respond in microseconds.
  * This is in microseconds because fast endpoints could be sub-millisecond and show up as a 0 if we tracked this in millis.

## Using this with Telemetry Metrics

To get these measurements aggregated over time, you would wrap these measurements using [TelemetryMetrics](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html) like:

```elixir
counter("plug.incoming_requests.count", description: "The total number of incoming requests", unit: :request),
counter("plug.successful_requests.count", description: "The total number of successful (2xx, 4xx) requests", unit: :request),
counter("plug.failed_requests.count", description: "The total number of failed (5xx) requests", unit: :request),
last_value("plug.response_time.duration", description: "The total response time for a request", unit: :microsecond)
```

You would then use any [telemetry reporter](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html#module-reporters) to forward these measurements to a metrics aggregator.

## License

MIT License
