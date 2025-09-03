defmodule Jido.SignalSerializationTest do
  use ExUnit.Case, async: false

  alias Jido.Signal
  alias Jido.Signal.Serialization.ErlangTermSerializer
  alias Jido.Signal.Serialization.JsonSerializer
  alias Jido.Signal.Serialization.MsgpackSerializer

  describe "Signal.serialize/1" do
    test "serializes a simple signal" do
      signal = %Signal{
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      {:ok, json} = Signal.serialize(signal)
      assert is_binary(json)

      decoded = Jason.decode!(json)
      assert decoded["type"] == "test.event"
      assert decoded["source"] == "/test/source"
      assert decoded["id"] == "test-id-123"
      assert decoded["specversion"] == "1.0.2"
    end

    test "serializes a signal with data" do
      signal = %Signal{
        data: %{key: "value", number: 42},
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      {:ok, json} = Signal.serialize(signal)
      assert is_binary(json)

      decoded = Jason.decode!(json)
      assert decoded["data"]["key"] == "value"
      assert decoded["data"]["number"] == 42
    end

    test "serializes a list of signals" do
      signals = [
        %Signal{id: "first-id", source: "/test/first", type: "first.event"},
        %Signal{id: "second-id", source: "/test/second", type: "second.event"}
      ]

      {:ok, json} = Signal.serialize(signals)
      assert is_binary(json)

      decoded = Jason.decode!(json)
      assert length(decoded) == 2
      assert Enum.at(decoded, 0)["type"] == "first.event"
      assert Enum.at(decoded, 1)["type"] == "second.event"
    end

    test "legacy serialize! function" do
      signal = %Signal{
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      json = Signal.serialize!(signal)
      assert is_binary(json)

      decoded = Jason.decode!(json)
      assert decoded["type"] == "test.event"
    end
  end

  describe "Signal.deserialize/1" do
    test "deserializes a simple signal" do
      json =
        ~s({"type":"test.event","source":"/test/source","id":"test-id-123","specversion":"1.0.2"})

      {:ok, signal} = Signal.deserialize(json)
      assert %Signal{} = signal
      assert signal.type == "test.event"
      assert signal.source == "/test/source"
      assert signal.id == "test-id-123"
      assert signal.specversion == "1.0.2"
    end

    test "deserializes a signal with data" do
      json =
        ~s({"type":"test.event","source":"/test/source","id":"test-id-123","specversion":"1.0.2","data":{"key":"value","number":42}})

      {:ok, signal} = Signal.deserialize(json)
      assert %Signal{} = signal
      assert signal.data["key"] == "value"
      assert signal.data["number"] == 42
    end

    test "deserializes a list of signals" do
      json = ~s([
        {"type":"first.event","source":"/test/first","id":"first-id","specversion":"1.0.2"},
        {"type":"second.event","source":"/test/second","id":"second-id","specversion":"1.0.2"}
      ])

      {:ok, signals} = Signal.deserialize(json)
      assert is_list(signals)
      assert length(signals) == 2

      first = Enum.at(signals, 0)
      second = Enum.at(signals, 1)

      assert first.type == "first.event"
      assert second.type == "second.event"
    end

    test "returns error for invalid JSON" do
      json = ~s({"type":"broken")

      result = Signal.deserialize(json)
      assert {:error, _reason} = result
    end

    test "returns error for invalid signal structure" do
      json = ~s({"not_a_type":"test.event"})

      result = Signal.deserialize(json)
      assert {:error, _reason} = result
    end
  end

  describe "round-trip serialization" do
    test "preserves signal data through serialization and deserialization" do
      original = %Signal{
        data: %{
          "boolean" => true,
          "nested" => %{"key" => "nested-value"},
          "number" => 42,
          "string" => "value"
        },
        datacontenttype: "application/json",
        dataschema: "https://example.com/schema",
        id: "test-id-123",
        source: "/test/source",
        subject: "test-subject",
        time: "2023-01-01T12:00:00Z",
        type: "test.event"
      }

      {:ok, json} = Signal.serialize(original)
      {:ok, deserialized} = Signal.deserialize(json)

      assert deserialized.type == original.type
      assert deserialized.source == original.source
      assert deserialized.id == original.id
      assert deserialized.subject == original.subject
      assert deserialized.time == original.time
      assert deserialized.datacontenttype == original.datacontenttype
      assert deserialized.dataschema == original.dataschema
      assert deserialized.data["string"] == original.data["string"]
      assert deserialized.data["number"] == original.data["number"]
      assert deserialized.data["boolean"] == original.data["boolean"]
      assert deserialized.data["nested"]["key"] == original.data["nested"]["key"]
    end

    test "preserves list of signals through serialization and deserialization" do
      originals = [
        %Signal{id: "first-id", source: "/test/first", type: "first.event"},
        %Signal{id: "second-id", source: "/test/second", type: "second.event"}
      ]

      {:ok, json} = Signal.serialize(originals)
      {:ok, deserialized} = Signal.deserialize(json)

      assert length(deserialized) == length(originals)

      originals
      |> Enum.zip(deserialized)
      |> Enum.each(fn {original, deserialized} ->
        assert deserialized.type == original.type
        assert deserialized.source == original.source
        assert deserialized.id == original.id
      end)
    end

    test "round-trip with different serializers" do
      signal = %Signal{
        data: %{"count" => 42, "message" => "hello"},
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      serializers = [
        JsonSerializer,
        ErlangTermSerializer,
        MsgpackSerializer
      ]

      for serializer <- serializers do
        {:ok, binary} = Signal.serialize(signal, serializer: serializer)
        {:ok, deserialized} = Signal.deserialize(binary, serializer: serializer)

        assert deserialized.type == signal.type
        assert deserialized.source == signal.source
        assert deserialized.id == signal.id
      end
    end
  end
end
