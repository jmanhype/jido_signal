defmodule Jido.Signal.RouterPatternTest do
  use ExUnit.Case, async: true

  alias Jido.Signal
  alias Jido.Signal.Router

  describe "matches?/2" do
    test "matches exact paths" do
      assert Router.matches?("user.created", "user.created")
      refute Router.matches?("user.updated", "user.created")
    end

    test "matches single wildcards" do
      assert Router.matches?("user.created", "user.*")
      assert Router.matches?("user.updated", "user.*")
      refute Router.matches?("payment.processed", "user.*")
      refute Router.matches?("user.profile.updated", "user.*")
    end

    test "matches multi-level wildcards" do
      assert Router.matches?("audit.user.created", "audit.**")
      assert Router.matches?("audit.payment.processed.success", "audit.**")
      assert Router.matches?("audit", "audit.**")
      refute Router.matches?("user.audit.created", "audit.**")
    end

    test "matches complex patterns" do
      assert Router.matches?("user.profile.updated", "user.*.updated")
      assert Router.matches?("system.audit.user.created", "system.audit.**")
      refute Router.matches?("user.profile.created", "user.*.updated")
    end

    test "handles invalid inputs" do
      refute Router.matches?(nil, "user.*")
      refute Router.matches?("user.created", nil)
      refute Router.matches?(123, "user.*")
      refute Router.matches?("user.created", 123)
    end
  end

  describe "filter/2" do
    setup do
      signals = [
        %Signal{data: %{id: 1}, id: "1", source: "test", type: "user.created"},
        %Signal{data: %{id: 1}, id: "2", source: "test", type: "user.updated"},
        %Signal{data: %{amount: 100}, id: "3", source: "test", type: "payment.processed"},
        %Signal{data: %{user_id: 1}, id: "4", source: "test", type: "audit.user.created"},
        %Signal{data: %{payment_id: 1}, id: "5", source: "test", type: "audit.payment.processed"}
      ]

      {:ok, signals: signals}
    end

    test "filters by exact match", %{signals: signals} do
      filtered = Router.filter(signals, "user.created")
      assert length(filtered) == 1
      assert hd(filtered).type == "user.created"
    end

    test "filters by single wildcard", %{signals: signals} do
      filtered = Router.filter(signals, "user.*")
      assert length(filtered) == 2
      assert Enum.all?(filtered, &String.starts_with?(&1.type, "user."))
    end

    test "filters by multi-level wildcard", %{signals: signals} do
      filtered = Router.filter(signals, "audit.**")
      assert length(filtered) == 2
      assert Enum.all?(filtered, &String.starts_with?(&1.type, "audit."))
    end

    test "returns empty list for non-matching pattern", %{signals: signals} do
      assert Router.filter(signals, "profile.**") == []
    end

    test "handles invalid inputs" do
      assert Router.filter(nil, "user.*") == []
      assert Router.filter([], nil) == []
      assert Router.filter("not a list", "user.*") == []
    end

    test "handles signals with nil types", %{signals: signals} do
      signals = [%Signal{id: "6", source: "test", type: nil} | signals]
      filtered = Router.filter(signals, "user.*")
      assert length(filtered) == 2
      assert Enum.all?(filtered, &String.starts_with?(&1.type, "user."))
    end
  end
end
