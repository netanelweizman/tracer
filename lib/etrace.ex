defmodule ETrace do
  @moduledoc """
  ETrace API
  """
  alias ETrace.{Server, Probe, Tool}
  import ETrace.Macros
  defmacro __using__(_opts) do
    quote do
      import ETrace
      import ETrace.Matcher
      :ok
    end
  end

  delegate :start, to: Server
  delegate :stop, to: Server
  delegate :stop_tool, to: Server

  delegate_1 :set_tool, to: Server

  def probe(params) do
    Probe.new(params)
  end

  def probe(type, params) do
    Probe.new([type: type] ++ params)
  end

  def tool(type, params) do
    Tool.new(type, params)
  end

  def start_tool(%{"__tool__": _} = tool) do
    Server.start_tool(tool)
  end
  def start_tool(type, params) do
    Server.start_tool(tool(type, params))
  end

end
