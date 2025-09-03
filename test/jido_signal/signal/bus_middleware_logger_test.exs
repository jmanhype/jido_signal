defmodule JidoTest.Signal.Bus.Middleware.Logger do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Jido.Signal
  alias Jido.Signal.Bus.Middleware.Logger, as: LoggerMiddleware
  alias Jido.Signal.Bus.Subscriber

  @moduletag :capture_log

  describe "LoggerMiddleware.init/1" do
    test "initializes with default options" do
      assert {:ok, config} = LoggerMiddleware.init([])

      assert config.level == :info
      assert config.log_publish == true
      assert config.log_dispatch == true
      assert config.log_errors == true
      assert config.include_signal_data == false
      assert config.max_data_length == 100
    end

    test "initializes with custom options" do
      opts = [
        level: :debug,
        log_publish: false,
        log_dispatch: true,
        log_errors: false,
        include_signal_data: true,
        max_data_length: 50
      ]

      assert {:ok, config} = LoggerMiddleware.init(opts)

      assert config.level == :debug
      assert config.log_publish == false
      assert config.log_dispatch == true
      assert config.log_errors == false
      assert config.include_signal_data == true
      assert config.max_data_length == 50
    end
  end

  describe "before_publish/3" do
    setup do
      context = %{
        bus_name: :test_bus,
        metadata: %{},
        timestamp: DateTime.utc_now()
      }

      signals = [
        %Signal{
          data: %{message: "test message", value: 1},
          id: "signal-1",
          source: "/test",
          type: "test.signal"
        },
        %Signal{
          data: %{value: 2},
          id: "signal-2",
          source: "/test",
          type: "another.signal"
        }
      ]

      {:ok, context: context, signals: signals}
    end

    test "logs publish event when log_publish is enabled", %{context: context, signals: signals} do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_publish: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log =~ "Bus test_bus: Publishing 2 signal(s)"
      assert log =~ "test.signal"
      assert log =~ "another.signal"
    end

    test "does not log when log_publish is disabled", %{context: context, signals: signals} do
      {:ok, config} = LoggerMiddleware.init(log_publish: false)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log == ""
    end

    test "includes signal data when include_signal_data is enabled", %{
      context: context,
      signals: signals
    } do
      {:ok, config} =
        LoggerMiddleware.init(level: :info, log_publish: true, include_signal_data: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log =~ "Signal signal-1 (test.signal)"
      assert log =~ "%{message: \"test message\", value: 1}"
    end

    test "truncates long signal data", %{context: context} do
      long_data = String.duplicate("a", 200)

      signals = [
        %Signal{
          data: long_data,
          id: "signal-1",
          source: "/test",
          type: "test.signal"
        }
      ]

      {:ok, config} =
        LoggerMiddleware.init(
          level: :info,
          log_publish: true,
          include_signal_data: true,
          max_data_length: 50
        )

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log =~ String.duplicate("a", 47) <> "..."
    end

    test "returns signals unchanged", %{context: context, signals: signals} do
      {:ok, config} = LoggerMiddleware.init([])

      assert {:cont, returned_signals, _config} =
               LoggerMiddleware.before_publish(signals, context, config)

      assert returned_signals == signals
    end
  end

  describe "after_publish/3" do
    setup do
      context = %{
        bus_name: :test_bus,
        metadata: %{},
        timestamp: DateTime.utc_now()
      }

      signals = [
        %Signal{data: %{}, id: "signal-1", source: "/test", type: "test.signal"}
      ]

      {:ok, context: context, signals: signals}
    end

    test "logs successful publish when log_publish is enabled", %{
      context: context,
      signals: signals
    } do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_publish: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.after_publish(signals, context, config)
        end)

      assert log =~ "Bus test_bus: Successfully published 1 signal(s)"
    end

    test "does not log when log_publish is disabled", %{context: context, signals: signals} do
      {:ok, config} = LoggerMiddleware.init(log_publish: false)

      log =
        capture_log(fn ->
          LoggerMiddleware.after_publish(signals, context, config)
        end)

      assert log == ""
    end
  end

  describe "before_dispatch/4" do
    setup do
      context = %{
        bus_name: :test_bus,
        metadata: %{},
        timestamp: DateTime.utc_now()
      }

      signal = %Signal{
        data: %{value: 1},
        id: "signal-1",
        source: "/test",
        type: "test.signal"
      }

      subscriber = %Subscriber{
        dispatch: {:pid, target: self(), delivery_mode: :async},
        id: "test-sub-id",
        path: "test.*",
        persistence_pid: nil,
        persistent?: false
      }

      {:ok, context: context, signal: signal, subscriber: subscriber}
    end

    test "logs dispatch event when log_dispatch is enabled", %{
      context: context,
      signal: signal,
      subscriber: subscriber
    } do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_dispatch: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_dispatch(signal, subscriber, context, config)
        end)

      assert log =~ "Bus test_bus: Dispatching signal signal-1 (test.signal)"
      assert log =~ "pid(#{inspect(self())}, async)"
    end

    test "does not log when log_dispatch is disabled", %{
      context: context,
      signal: signal,
      subscriber: subscriber
    } do
      {:ok, config} = LoggerMiddleware.init(log_dispatch: false)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_dispatch(signal, subscriber, context, config)
        end)

      assert log == ""
    end

    test "returns signal unchanged", %{context: context, signal: signal, subscriber: subscriber} do
      {:ok, config} = LoggerMiddleware.init([])

      assert {:cont, returned_signal, _config} =
               LoggerMiddleware.before_dispatch(signal, subscriber, context, config)

      assert returned_signal == signal
    end
  end

  describe "after_dispatch/5" do
    setup do
      context = %{
        bus_name: :test_bus,
        metadata: %{},
        timestamp: DateTime.utc_now()
      }

      signal = %Signal{
        data: %{value: 1},
        id: "signal-1",
        source: "/test",
        type: "test.signal"
      }

      subscriber = %Subscriber{
        dispatch: {:pid, target: self(), delivery_mode: :async},
        id: "test-sub-id",
        path: "test.*",
        persistence_pid: nil,
        persistent?: false
      }

      {:ok, context: context, signal: signal, subscriber: subscriber}
    end

    test "logs successful dispatch when log_dispatch is enabled", %{
      context: context,
      signal: signal,
      subscriber: subscriber
    } do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_dispatch: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.after_dispatch(signal, subscriber, :ok, context, config)
        end)

      assert log =~ "Bus test_bus: Successfully dispatched signal signal-1"
      assert log =~ "pid(#{inspect(self())}, async)"
    end

    test "logs error dispatch when log_errors is enabled", %{
      context: context,
      signal: signal,
      subscriber: subscriber
    } do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_errors: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.after_dispatch(
            signal,
            subscriber,
            {:error, :timeout},
            context,
            config
          )
        end)

      assert log =~ "[error]"
      assert log =~ "Bus test_bus: Failed to dispatch signal signal-1"
      assert log =~ ":timeout"
    end

    test "does not log when relevant flags are disabled", %{
      context: context,
      signal: signal,
      subscriber: subscriber
    } do
      {:ok, config} = LoggerMiddleware.init(log_dispatch: false, log_errors: false)

      log =
        capture_log(fn ->
          LoggerMiddleware.after_dispatch(signal, subscriber, :ok, context, config)
        end)

      assert log == ""

      log =
        capture_log(fn ->
          LoggerMiddleware.after_dispatch(
            signal,
            subscriber,
            {:error, :timeout},
            context,
            config
          )
        end)

      assert log == ""
    end
  end

  describe "dispatch info formatting" do
    test "formats pid dispatch correctly" do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_dispatch: true)

      context = %{bus_name: :test_bus, metadata: %{}, timestamp: DateTime.utc_now()}
      signal = %Signal{data: %{}, id: "signal-1", source: "/test", type: "test.signal"}

      subscriber = %Subscriber{
        dispatch: {:pid, target: self(), delivery_mode: :sync},
        id: "test-sub-id",
        path: "test.*",
        persistence_pid: nil,
        persistent?: false
      }

      log =
        capture_log(fn ->
          LoggerMiddleware.before_dispatch(signal, subscriber, context, config)
        end)

      assert log =~ "pid(#{inspect(self())}, sync)"
    end

    test "formats function dispatch correctly" do
      {:ok, config} = LoggerMiddleware.init(level: :info, log_dispatch: true)

      context = %{bus_name: :test_bus, metadata: %{}, timestamp: DateTime.utc_now()}
      signal = %Signal{data: %{}, id: "signal-1", source: "/test", type: "test.signal"}

      subscriber = %Subscriber{
        dispatch: {:function, {MyModule, :my_function}},
        id: "test-sub-id",
        path: "test.*",
        persistence_pid: nil,
        persistent?: false
      }

      log =
        capture_log(fn ->
          LoggerMiddleware.before_dispatch(signal, subscriber, context, config)
        end)

      assert log =~ "function(Elixir.MyModule.my_function)"
    end
  end

  describe "signal data formatting" do
    setup do
      context = %{bus_name: :test_bus, metadata: %{}, timestamp: DateTime.utc_now()}
      {:ok, context: context}
    end

    test "handles nil data", %{context: context} do
      signals = [%Signal{data: nil, id: "signal-1", source: "/test", type: "test.signal"}]

      {:ok, config} =
        LoggerMiddleware.init(level: :info, log_publish: true, include_signal_data: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log =~ "nil"
    end

    test "handles binary data", %{context: context} do
      signals = [
        %Signal{data: "binary data", id: "signal-1", source: "/test", type: "test.signal"}
      ]

      {:ok, config} =
        LoggerMiddleware.init(level: :info, log_publish: true, include_signal_data: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log =~ "binary data"
    end

    test "handles complex data structures", %{context: context} do
      signals = [
        %Signal{
          data: %{nested: %{data: [1, 2, 3]}},
          id: "signal-1",
          source: "/test",
          type: "test.signal"
        }
      ]

      {:ok, config} =
        LoggerMiddleware.init(level: :info, log_publish: true, include_signal_data: true)

      log =
        capture_log(fn ->
          LoggerMiddleware.before_publish(signals, context, config)
        end)

      assert log =~ "%{nested: %{data: [1, 2, 3]}}"
    end
  end
end
