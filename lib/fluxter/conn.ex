defmodule Fluxter.Conn do
  @moduledoc false

  use GenServer

  alias Fluxter.Packet

  require Logger

  defstruct [:sock, :prefix, :host, :port]

  def new(host, port) when is_binary(host) do
    new(String.to_charlist(host), port)
  end

  def new(host, port) do
    %__MODULE__{host: host, port: port}
  end

  def start_link(%__MODULE__{} = conn, worker) do
    GenServer.start_link(__MODULE__, conn, name: worker)
  end

  def write(worker, name, tags, fields)
      when (is_binary(name) or is_list(name)) and is_list(tags) and is_list(fields) do
    GenServer.cast(worker, {:write, name, tags, fields})
  end

  def init(conn) do
    {:ok, sock} = :gen_udp.open(0, active: false)
    {:ok, %{conn | sock: sock}}
  end

  def handle_cast({:write, name, tags, fields}, conn) do
    packet = Packet.build(conn.prefix, name, tags, fields)
    :gen_udp.send(conn.sock, conn.host, conn.port, packet)

    {:noreply, conn}
  end

  def handle_info({:inet_reply, _sock, :ok}, conn) do
    {:noreply, conn}
  end

  def handle_info({:inet_reply, _sock, {:error, reason}}, conn) do
    Logger.error([
      "Failed to send metric, reason: ",
      ?",
      :inet.format_error(reason),
      ?"
    ])

    {:noreply, conn}
  end
end
