defmodule Tcptest.Handler do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(client_socket) do
    :gen_tcp.send(client_socket, "WELCOME\r\n")
    Process.send_after(self(), {:tcp, client_socket}, 0)
    {:ok, nil}
  end

  def handle_info({:tcp, socket}, _) do
    case :gen_tcp.recv(socket, 0, 1000 * 30) do
      {:ok, data} ->
        data = String.trim(data)
        handle_msg(socket, data)

      {:error, reason} ->
        IO.puts("err on recv from socket > #{inspect(reason)}")
        handle_msg(socket, "CLOSE")
    end

    {:noreply, nil}
  end

  def handle_msg(socket, "CLOSE") do
    :gen_tcp.close(socket)
    {:stop, :normal, nil}
  end

  def handle_msg(socket, data) do
    :gen_tcp.send(socket, "Echo: #{data}\n")
    send(self(), {:tcp, socket})
    {:noreply, nil}
  end
end
