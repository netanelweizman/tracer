defmodule Tracer.Clause.Test do
  use ExUnit.Case
  alias Tracer.Clause

  test "new returns an empty clause" do
    assert Clause.new() == %Clause{}
  end

  test "put_mfa returns error when arguments are invalid" do
    res = Clause.new()
      |> Clause.put_mfa(5, %{})

    assert res == {:error, :invalid_mfa}
  end

  test "put_mfa stores mfa in clause and set type to :call" do
    clause = Clause.new()
      |> Clause.put_mfa(Map, :get, 2)

    assert Clause.get_mfa(clause) == {Map, :get, 2}
    assert Clause.get_type(clause) == :call
  end

  test "put_mfa accepts 0, 1, or 2 arguments" do
    clause = Clause.new()
      |> Clause.put_mfa(Map, :get)

    assert Clause.get_mfa(clause) == {Map, :get, :_}

    clause = Clause.put_mfa(clause, Map)
    assert Clause.get_mfa(clause) == {Map, :_, :_}

    clause = Clause.put_mfa(clause)
    assert Clause.get_mfa(clause) == {:_, :_, :_}
  end

  test "put_fun accepts an external function" do
    clause = Clause.new()
      |> Clause.put_fun(&Map.get/3)

    assert Clause.get_mfa(clause) == {Map, :get, 3}
  end

  test "valid? checks that mfa has been set" do
    res = Clause.new()
      |> Clause.valid?()

    assert res == {:error, :missing_mfa}
  end

  test "apply validates clause before applying clause" do
    res = Clause.new()
      |> Clause.apply()

    assert res == {:error, :missing_mfa}
  end

  test "apply stores the number of matches in matches" do
    clause = Clause.new()
      |> Clause.put_mfa(Map, :get, 2)
      |> Clause.apply()

    assert Clause.matches(clause) == 1
  end

  test "apply with not_remove equals to false removes the clause" do
    clause = Clause.new()
      |> Clause.put_mfa(Map, :get, 2)
      |> Clause.apply()

    assert Clause.matches(clause) == 1

    match_spec = :erlang.trace_info({Map, :get, 2}, :match_spec)
    assert match_spec == {:match_spec, []}

    clause = Clause.apply(clause, false)
    assert Clause.matches(clause) == 0
    match_spec = :erlang.trace_info({Map, :get, 2}, :match_spec)
    assert match_spec == {:match_spec, false}
  end

  test "valid_flags? return error when a flag is invalid" do
    assert Clause.valid_flags?([:global,:local]) == :ok
    res = Clause.valid_flags?([:global, :foo, :bar])
    assert res == {:error, [invalid_clause_flag: :bar,
                            invalid_clause_flag: :foo]}
  end

  test "set_flags check for valid flags" do
    res = Clause.new()
      |> Clause.set_flags([:global, :foo, :bar])

    assert res == {:error, [invalid_clause_flag: :bar,
                            invalid_clause_flag: :foo]}
  end

  test "set_flags sets the flags and get_flags retrieve them" do
    flags = Clause.new()
      |> Clause.set_flags([:global, :call_count])
      |> Clause.get_flags()

    assert flags == [:global, :call_count]
  end

  test "get_trace_cmd includes expected parameters" do
    cmd = Clause.new()
      |> Clause.put_mfa(Map, :get, 2)
      |> Clause.add_matcher([{[:"$1", :"$2"], [is_atom: :"$2"], [message: [[:y, :"$2"]]]}])
      |> Clause.set_flags([:global, :call_count])
      |> Clause.get_trace_cmd()

    assert Keyword.get(cmd, :fun) == &:erlang.trace_pattern/3
    assert Keyword.get(cmd, :mfa) == {Map, :get, 2}
    assert Keyword.get(cmd, :match_spec) == [{[:"$1", :"$2"], [is_atom: :"$2"], [message: [[:y, :"$2"]]]}]
    assert Keyword.get(cmd, :flag_list) == [:global, :call_count]
  end

  test "get_trace_cmd raises an exception when the clause is invalid" do
    clause = Clause.new()
      |> Clause.add_matcher([{[:"$1", :"$2"], [is_atom: :"$2"], [message: [[:y, :"$2"]]]}])
      |> Clause.set_flags([:global, :call_count])

    assert_raise RuntimeError, "invalid clause {:error, :missing_mfa}", fn ->
      Clause.get_trace_cmd(clause)
    end
  end

end
