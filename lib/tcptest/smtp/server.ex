defmodule Tcptest.Smtp.Server do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(:no_args) do
    {:ok, socket} =
      :gen_tcp.listen(25, [:binary, packet: :line, active: false, reuseaddr: true])

    IO.puts("Server is listening on port 25...")
    Process.send_after(self(), {:loop, socket}, 0)
    {:ok, nil}
  end

  def handle_info({:loop, socket}, _) do
    accept(socket)
  end

  defp accept(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    spawn_link(Tcptest.Smtp.Handler, :start_link, [client_socket])
    send(self(), {:loop, socket})
    {:noreply, nil}
  end
end
