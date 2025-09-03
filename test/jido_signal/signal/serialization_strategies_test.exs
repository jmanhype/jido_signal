defmodule Jido.Signal.SerializationStrategiesTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias Jido.Signal.Serialization.{ErlangTermSerializer, JsonSerializer, MsgpackSerializer}

  @serializers [
    {"JSON", JsonSerializer},
    {"Erlang Term", ErlangTermSerializer},
    {"MessagePack", MsgpackSerializer}
  ]

  describe "Signal serialization with different strategies" do
    test "all serializers can handle basic Signal" do
      signal = %Signal{
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      for {_name, serializer} <- @serializers do
        {:ok, binary} = Signal.serialize(signal, serializer: serializer)
        assert is_binary(binary)

        {:ok, deserialized} = Signal.deserialize(binary, serializer: serializer)
        assert %Signal{} = deserialized
        assert deserialized.type == signal.type
        assert deserialized.source == signal.source
        assert deserialized.id == signal.id
      end
    end

    test "all serializers can handle Signal with data" do
      signal = %Signal{
        data: %{
          "active" => true,
          "count" => 42,
          "message" => "hello world",
          "metadata" => %{"version" => "1.0"}
        },
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      for {_name, serializer} <- @serializers do
        {:ok, binary} = Signal.serialize(signal, serializer: serializer)
        {:ok, deserialized} = Signal.deserialize(binary, serializer: serializer)

        assert deserialized.type == signal.type
        assert deserialized.source == signal.source
        assert deserialized.id == signal.id

        # Data comparison might vary by serializer due to type preservation differences
        case serializer do
          ErlangTermSerializer ->
            # Erlang terms preserve exact types
            assert deserialized.data == signal.data

          JsonSerializer ->
            # JSON preserves structure but string keys
            assert deserialized.data["message"] == "hello world"
            assert deserialized.data["count"] == 42
            assert deserialized.data["active"] == true
            assert deserialized.data["metadata"]["version"] == "1.0"

          MsgpackSerializer ->
            # MessagePack preserves structure but converts atoms to strings
            assert deserialized.data["message"] == "hello world"
            assert deserialized.data["count"] == 42
            assert deserialized.data["active"] == true
            assert deserialized.data["metadata"]["version"] == "1.0"
        end
      end
    end

    test "all serializers can handle Signal lists" do
      signals = [
        %Signal{id: "first-id", source: "/test/first", type: "first.event"},
        %Signal{id: "second-id", source: "/test/second", type: "second.event"}
      ]

      for {_name, serializer} <- @serializers do
        {:ok, binary} = Signal.serialize(signals, serializer: serializer)
        assert is_binary(binary)

        {:ok, deserialized} = Signal.deserialize(binary, serializer: serializer)
        assert is_list(deserialized)
        assert length(deserialized) == 2

        first = Enum.at(deserialized, 0)
        second = Enum.at(deserialized, 1)

        assert first.type == "first.event"
        assert second.type == "second.event"
      end
    end

    test "all serializers handle full Signal structure" do
      signal = %Signal{
        data: %{
          "list" => [1, 2, 3],
          "mixed" => %{
            "boolean" => false,
            "number" => 3.14,
            "string" => "text"
          },
          "nested" => %{
            "deep" => %{"value" => 42}
          }
        },
        datacontenttype: "application/json",
        dataschema: "https://example.com/schema",
        id: "complex-id-123",
        source: "/complex/source",
        subject: "test-subject",
        time: "2023-01-01T12:00:00Z",
        type: "complex.event"
      }

      for {_name, serializer} <- @serializers do
        {:ok, binary} = Signal.serialize(signal, serializer: serializer)
        {:ok, deserialized} = Signal.deserialize(binary, serializer: serializer)

        # Verify all required fields
        assert deserialized.type == signal.type
        assert deserialized.source == signal.source
        assert deserialized.id == signal.id
        assert deserialized.subject == signal.subject
        assert deserialized.time == signal.time
        assert deserialized.datacontenttype == signal.datacontenttype
        assert deserialized.dataschema == signal.dataschema

        # Verify data structure is preserved (with type variations)
        assert deserialized.data["list"] == [1, 2, 3]

        case serializer do
          ErlangTermSerializer ->
            assert deserialized.data == signal.data

          _ ->
            # JSON and MessagePack preserve structure but may convert types
            assert deserialized.data["nested"]["deep"]["value"] == 42
            assert deserialized.data["mixed"]["string"] == "text"
            assert deserialized.data["mixed"]["number"] == 3.14
            assert deserialized.data["mixed"]["boolean"] == false
        end
      end
    end

    test "serializer size comparison" do
      signal = %Signal{
        data: %{
          "message" => "This is a test message for size comparison",
          "metadata" => %{
            "created_at" => "2023-01-01T12:00:00Z",
            "tags" => ["test", "benchmark", "comparison"],
            "version" => "1.0.0"
          },
          "numbers" => Enum.to_list(1..100)
        },
        id: "benchmark-id-123",
        source: "/benchmark/source",
        type: "benchmark.event"
      }

      sizes =
        for {name, serializer} <- @serializers do
          {:ok, binary} = Signal.serialize(signal, serializer: serializer)
          {name, byte_size(binary)}
        end

      # Verify all serializers produce some output
      for {name, size} <- sizes do
        assert size > 0, "#{name} should produce non-empty output"
      end
    end

    test "serialization performance comparison" do
      signal = %Signal{
        data: %{
          "list" => Enum.to_list(1..500),
          "payload" => String.duplicate("x", 1000)
        },
        id: "perf-123",
        source: "/perf/test",
        type: "performance.test"
      }

      for {_name, serializer} <- @serializers do
        # Warm up
        Signal.serialize(signal, serializer: serializer)

        # Time serialization
        {serialize_time, {:ok, binary}} =
          :timer.tc(fn -> Signal.serialize(signal, serializer: serializer) end)

        # Time deserialization
        {deserialize_time, {:ok, _result}} =
          :timer.tc(fn -> Signal.deserialize(binary, serializer: serializer) end)

        # Basic performance sanity check (should complete within reasonable time)
        assert serialize_time < 100_000
        assert deserialize_time < 100_000
      end
    end
  end

  describe "default serializer configuration" do
    test "uses JsonSerializer by default" do
      signal = %Signal{id: "test-123", source: "/test", type: "test.event"}

      # Should use JSON by default
      {:ok, binary} = Signal.serialize(signal)
      {:ok, deserialized} = Signal.deserialize(binary)

      assert deserialized.type == signal.type
      assert Jason.decode!(binary)["type"] == "test.event"
    end

    test "can override serializer per operation" do
      signal = %Signal{id: "test-123", source: "/test", type: "test.event"}

      # Use Erlang term serializer explicitly
      {:ok, term_binary} = Signal.serialize(signal, serializer: ErlangTermSerializer)
      {:ok, term_result} = Signal.deserialize(term_binary, serializer: ErlangTermSerializer)

      assert term_result.type == signal.type

      # Use MessagePack serializer explicitly
      {:ok, msgpack_binary} =
        Signal.serialize(signal, serializer: MsgpackSerializer)

      {:ok, msgpack_result} =
        Signal.deserialize(msgpack_binary, serializer: MsgpackSerializer)

      assert msgpack_result.type == signal.type

      # Different serializers should produce different binary formats
      {:ok, json_binary} = Signal.serialize(signal)
      refute term_binary == json_binary
      refute msgpack_binary == json_binary
      refute term_binary == msgpack_binary
    end
  end
end
