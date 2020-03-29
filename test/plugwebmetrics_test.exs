defmodule PlugwebmetricsTest do
  use ExUnit.Case
  use Plug.Test

  defmodule MySuccessPlug do
    use Plug.Builder
    require Plugwebmetrics

    plug Plugwebmetrics
    plug :send_resp, 200

    defp send_resp(conn, status) do
      Plug.Conn.send_resp(conn, status, "Success")
    end
  end

  defmodule MyFailedPlug do
    use Plug.Builder
    require Plugwebmetrics

    plug Plugwebmetrics
    plug :send_resp, 500

    defp send_resp(conn, status) do
      Plug.Conn.send_resp(conn, status, "Server Error")
    end
  end

  defmodule MyBadRequestPlug do
    use Plug.Builder
    require Plugwebmetrics

    plug Plugwebmetrics
    plug :send_resp, 400

    defp send_resp(conn, status) do
      Plug.Conn.send_resp(conn, status, "Bad request")
    end
  end


  # Telemetry attach/4 requires a unique handler id, so we create a random one for
  # each test along with automatic teardown.
  setup do
    unique_handler_id = {:foo, :rand.uniform(100)}

    on_exit(fn ->
      :telemetry.detach(unique_handler_id)
    end)

    {:ok, h: unique_handler_id}
  end

  describe "plug.incoming_requests" do
    setup context do
      event = [:plug, :incoming_requests]

      attach(context.h, event)

      MySuccessPlug.call(conn(:get, "/"), [])

      assert_received {:event, ^event, measurements, metadata}
      %{measurements: measurements, metadata: metadata}
    end

    test "the incoming request count is triggered", %{measurements: measurements} do
      assert measurements.count == 1
    end

    test "the method called is supplied as metadata", %{metadata: metadata} do
      assert metadata.method == "GET"
    end

    test "the endpoint/request_path is supplied as metadata", %{metadata: metadata} do
      assert metadata.request_path == "/"
    end
  end

  describe "plug.successful_requests" do
    setup context do
      event = [:plug, :successful_requests]

      attach(context.h, event)

      MySuccessPlug.call(conn(:get, "/"), [])

      assert_received {:event, ^event, measurements, metadata}
      %{measurements: measurements, metadata: metadata}
    end

    test "the successful request count is triggered", %{measurements: measurements} do
      assert measurements.count == 1
    end

    test "the method called is supplied as metadata", %{metadata: metadata} do
      assert metadata.method == "GET"
    end

    test "the endpoint/request_path is supplied as metadata", %{metadata: metadata} do
      assert metadata.request_path == "/"
    end

    test "the duration is supplied as metadata", %{metadata: metadata} do
      assert metadata.duration != 0
    end

    test "the status is supplied as metadata", %{metadata: metadata} do
      assert metadata.status == 200
    end
  end

  describe "plug.failed_requests" do
    setup context do
      event = [:plug, :failed_requests]

      attach(context.h, event)

      MyFailedPlug.call(conn(:get, "/"), [])

      assert_received {:event, ^event, measurements, metadata}
      %{measurements: measurements, metadata: metadata}
    end

    test "the failed request count is triggered", %{measurements: measurements} do
      assert measurements.count == 1
    end

    test "the method called is supplied as metadata", %{metadata: metadata} do
      assert metadata.method == "GET"
    end

    test "the endpoint/request_path is supplied as metadata", %{metadata: metadata} do
      assert metadata.request_path == "/"
    end

    test "the duration is supplied as metadata", %{metadata: metadata} do
      assert metadata.duration != 0
    end

    test "the status is supplied as metadata", %{metadata: metadata} do
      assert metadata.status == 500
    end
  end

  describe "plug.response_time" do
    setup context do
      event = [:plug, :response_time]

      attach(context.h, event)

      MySuccessPlug.call(conn(:get, "/"), [])

      assert_received {:event, ^event, measurements, metadata}
      %{measurements: measurements, metadata: metadata}
    end

    test "the duration is triggered", %{measurements: measurements} do
      # It's in micros and is variable based on the execution time of the test,
      # so we just assert that it's non-zero instead of a particular value
      assert measurements.duration != 0
    end

    test "the method called is supplied as metadata", %{metadata: metadata} do
      assert metadata.method == "GET"
    end

    test "the endpoint/request_path is supplied as metadata", %{metadata: metadata} do
      assert metadata.request_path == "/"
    end

    test "the duration is supplied as metadata", %{metadata: metadata} do
      assert metadata.duration != 0
    end

    test "the status is supplied as metadata", %{metadata: metadata} do
      assert metadata.status == 200
    end

    test "it's triggered for failed requests" do
      MyFailedPlug.call(conn(:get, "/"), [])

      assert_received {:event, [:plug, :response_time], _, _}
    end

    test "it's triggered for bad requests" do
      MyBadRequestPlug.call(conn(:get, "/"), [])

      assert_received {:event, [:plug, :response_time], _, _}
    end
  end

  describe "on a 40x response" do
    test "the failed request count is not triggered", %{h: h} do
      event = [:plug, :failed_requests]
      attach(h, event)

      MyBadRequestPlug.call(conn(:get, "/"), [])

      refute_received {:event, ^event, _, _}
    end

    test "the successful request count is triggered", %{h: h} do
      event = [:plug, :successful_requests]
      attach(h, event)

      MyBadRequestPlug.call(conn(:get, "/"), [])

      assert_received {:event, ^event, _, _}
    end

    test "the status is correct", %{h: h} do
      event = [:plug, :successful_requests]
      attach(h, event)

      MyBadRequestPlug.call(conn(:get, "/"), [])

      assert_received {:event, ^event, _, metadata}
      assert metadata.status == 400
    end
  end

  defp attach(handler_id, event) do
    :telemetry.attach(
      handler_id,
      event,
      fn event, measurements, metadata, _ ->
        send(self(), {:event, event, measurements, metadata})
      end,
      nil
    )
  end
end
