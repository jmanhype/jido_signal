defmodule JidoTest.Signal.Bus.RecordedSignalSerializationTest do
  use ExUnit.Case, async: false

  alias Jido.Signal
  alias Jido.Signal.Bus.RecordedSignal

  describe "RecordedSignal.serialize/1" do
    test "serializes a simple recorded signal" do
      signal = %Signal{
        id: "test-id-123",
        source: "/test/source",
        type: "test.event"
      }

      recorded = %RecordedSignal{
        created_at: DateTime.from_naive!(~N[2023-01-01 12:00:00], "Etc/UTC"),
        id: "record-123",
        signal: signal,
        type: "test.event"
      }

      json = RecordedSignal.serialize(recorded)
      assert is_binary(json)

      decoded = Jason.decode!(json)
      assert decoded["id"] == "record-123"
      assert decoded["type"] == "test.event"
      assert decoded["created_at"] == "2023-01-01T12:00:00Z"
      assert decoded["signal"]["type"] == "test.event"
      assert decoded["signal"]["source"] == "/test/source"
      assert decoded["signal"]["id"] == "test-id-123"
    end

    test "serializes a list of recorded signals" do
      signal1 = %Signal{id: "first-id", source: "/test/first", type: "first.event"}
      signal2 = %Signal{id: "second-id", source: "/test/second", type: "second.event"}

      records = [
        %RecordedSignal{
          created_at: DateTime.from_naive!(~N[2023-01-01 12:00:00], "Etc/UTC"),
          id: "record-1",
          signal: signal1,
          type: "first.event"
        },
        %RecordedSignal{
          created_at: DateTime.from_naive!(~N[2023-01-01 13:00:00], "Etc/UTC"),
          id: "record-2",
          signal: signal2,
          type: "second.event"
        }
      ]

      json = RecordedSignal.serialize(records)
      assert is_binary(json)

      decoded = Jason.decode!(json)
      assert length(decoded) == 2
      assert Enum.at(decoded, 0)["id"] == "record-1"
      assert Enum.at(decoded, 1)["id"] == "record-2"
      assert Enum.at(decoded, 0)["signal"]["type"] == "first.event"
      assert Enum.at(decoded, 1)["signal"]["type"] == "second.event"
    end
  end

  describe "RecordedSignal.deserialize/1" do
    test "deserializes a simple recorded signal" do
      json = ~s({
        "id": "record-123",
        "type": "test.event",
        "created_at": "2023-01-01T12:00:00Z",
        "signal": {
          "type": "test.event",
          "source": "/test/source",
          "id": "test-id-123",
          "specversion": "1.0.2"
        }
      })

      {:ok, recorded} = RecordedSignal.deserialize(json)
      assert %RecordedSignal{} = recorded
      assert recorded.id == "record-123"
      assert recorded.type == "test.event"
      assert recorded.created_at == DateTime.from_naive!(~N[2023-01-01 12:00:00], "Etc/UTC")
      assert recorded.signal.type == "test.event"
      assert recorded.signal.source == "/test/source"
      assert recorded.signal.id == "test-id-123"
    end

    test "deserializes a list of recorded signals" do
      json = ~s([
        {
          "id": "record-1",
          "type": "first.event",
          "created_at": "2023-01-01T12:00:00Z",
          "signal": {
            "type": "first.event",
            "source": "/test/first",
            "id": "first-id",
            "specversion": "1.0.2"
          }
        },
        {
          "id": "record-2",
          "type": "second.event",
          "created_at": "2023-01-01T13:00:00Z",
          "signal": {
            "type": "second.event",
            "source": "/test/second",
            "id": "second-id",
            "specversion": "1.0.2"
          }
        }
      ])

      {:ok, records} = RecordedSignal.deserialize(json)
      assert is_list(records)
      assert length(records) == 2

      first = Enum.at(records, 0)
      second = Enum.at(records, 1)

      assert first.id == "record-1"
      assert second.id == "record-2"
      assert first.signal.type == "first.event"
      assert second.signal.type == "second.event"
    end

    test "returns error for invalid JSON" do
      json = ~s({"id":"broken")

      result = RecordedSignal.deserialize(json)
      assert {:error, _reason} = result
    end

    test "returns error for invalid recorded signal structure" do
      json = ~s({"not_a_recorded_signal":"test"})

      result = RecordedSignal.deserialize(json)
      assert {:error, _reason} = result
    end
  end

  describe "round-trip serialization" do
    test "preserves recorded signal data through serialization and deserialization" do
      signal = %Signal{
        data: %{
          "boolean" => true,
          "number" => 42,
          "string" => "value"
        },
        id: "test-id-123",
        source: "/test/source",
        subject: "test-subject",
        type: "test.event"
      }

      original = %RecordedSignal{
        created_at: DateTime.from_naive!(~N[2023-01-01 12:00:00], "Etc/UTC"),
        id: "record-123",
        signal: signal,
        type: "test.event"
      }

      json = RecordedSignal.serialize(original)
      {:ok, deserialized} = RecordedSignal.deserialize(json)

      assert deserialized.id == original.id
      assert deserialized.type == original.type

      assert DateTime.to_iso8601(deserialized.created_at) ==
               DateTime.to_iso8601(original.created_at)

      assert deserialized.signal.type == original.signal.type
      assert deserialized.signal.source == original.signal.source
      assert deserialized.signal.id == original.signal.id
      assert deserialized.signal.subject == original.signal.subject
      assert deserialized.signal.data["string"] == original.signal.data["string"]
      assert deserialized.signal.data["number"] == original.signal.data["number"]
      assert deserialized.signal.data["boolean"] == original.signal.data["boolean"]
    end

    test "preserves list of recorded signals through serialization and deserialization" do
      signal1 = %Signal{id: "first-id", source: "/test/first", type: "first.event"}
      signal2 = %Signal{id: "second-id", source: "/test/second", type: "second.event"}

      originals = [
        %RecordedSignal{
          created_at: DateTime.from_naive!(~N[2023-01-01 12:00:00], "Etc/UTC"),
          id: "record-1",
          signal: signal1,
          type: "first.event"
        },
        %RecordedSignal{
          created_at: DateTime.from_naive!(~N[2023-01-01 13:00:00], "Etc/UTC"),
          id: "record-2",
          signal: signal2,
          type: "second.event"
        }
      ]

      json = RecordedSignal.serialize(originals)
      {:ok, deserialized} = RecordedSignal.deserialize(json)

      assert length(deserialized) == length(originals)

      originals
      |> Enum.zip(deserialized)
      |> Enum.each(fn {original, deserialized} ->
        assert deserialized.id == original.id
        assert deserialized.type == original.type

        assert DateTime.to_iso8601(deserialized.created_at) ==
                 DateTime.to_iso8601(original.created_at)

        assert deserialized.signal.type == original.signal.type
        assert deserialized.signal.source == original.signal.source
        assert deserialized.signal.id == original.signal.id
      end)
    end
  end
end
