defmodule Plugwebmetrics do
  @moduledoc """

  This plug provides a few standard web metrics (ex: number of incoming requests, response time duration,
  number of succcessful/failed requests).

  ## Usage

    defmodule MyRouter do
      use Plug.Router
      require Plugwebmetrics

      plug(:match)
      plug Plugwebmetrics
      plug(:dispatch)

      get("/hello", do: send_resp(conn, 200, "world"))
    end
  """
  @behaviour Plug

  require Logger

  @impl true
   def init(opts) do
    opts
  end

  @impl true
  def call(conn, _opts) do
    request_metadata = %{
      method: conn.method,
      request_path: conn.request_path,
    }

    start = System.monotonic_time()

    :telemetry.execute([:plug, :incoming_requests], %{count: 1}, request_metadata)

    Plug.Conn.register_before_send(conn, fn conn ->
      stop = System.monotonic_time()
      duration_micros = System.convert_time_unit(stop - start, :native, :microsecond)

      response_metadata = %{
        duration: duration_micros,
        status: conn.status
      }

      total_metadata = Map.merge(request_metadata, response_metadata)

      :telemetry.execute([:plug, :response_time], %{duration: duration_micros}, total_metadata)

      cond do
        conn.status >= 200 and conn.status < 500 ->
          :telemetry.execute([:plug, :successful_requests], %{count: 1}, total_metadata)
        conn.status >= 500 and conn.status < 600 ->
          :telemetry.execute([:plug, :failed_requests], %{count: 1}, total_metadata)

        true -> :ok
      end

      conn
    end)
  end
end
