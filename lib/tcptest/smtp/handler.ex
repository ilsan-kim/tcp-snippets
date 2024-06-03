defmodule Tcptest.Smtp.Handler do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init(client_socket) do
    :gen_tcp.send(client_socket, "220 tricolor-ilsan-kim.com SMTP Server Ready.\r\n")
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
        handle_msg(socket, "QUIT")
    end

    {:noreply, nil}
  end

  def handle_msg(socket, msg) do
    cond do
      String.starts_with?(msg, ["HELO", "EHLO"]) ->
        handle_hello(socket, msg)

      String.starts_with?(msg, ["MAIL FROM", "RCPT TO"]) ->
        handle_cmd(socket, msg)

      String.starts_with?(msg, "DATA") ->
        handle_msg_start(socket, msg)

      String.starts_with?(msg, ".") ->
        handle_msg_end(socket, msg)

      String.starts_with?(msg, "QUIT") ->
        handle_cmd(socket, "QUIT")

      true ->
        handle_line(socket, msg)
    end
  end

  def handle_line(socket, msg) do
    IO.puts(msg)
    Process.send_after(self(), {:tcp, socket}, 0)
    {:noreply, nil}
  end

  def handle_hello(socket, msg) do
    IO.puts(msg)
    :gen_tcp.send(socket, "250 Hello\r\n")
    Process.send_after(self(), {:tcp, socket}, 0)
    {:noreply, nil}
  end

  def handle_msg_start(socket, msg) do
    IO.puts(msg)
    :gen_tcp.send(socket, "354 Start mail input; end with <CRLF>.<CRLF>\r\n")
    Process.send_after(self(), {:tcp, socket}, 0)
    {:noreply, nil}
  end

  def handle_msg_end(socket, msg) do
    IO.puts(msg)
    :gen_tcp.send(socket, "250 OK\r\n")
    Process.send_after(self(), {:tcp, socket}, 0)
    {:noreply, nil}
  end

  def handle_cmd(socket, "QUIT") do
    :gen_tcp.send(socket, "221 GoodBye")
    :gen_tcp.close(socket)
    {:stop, :normal, 0}
  end

  def handle_cmd(socket, msg) do
    IO.puts(msg)
    :gen_tcp.send(socket, "250 OK\r\n")
    Process.send_after(self(), {:tcp, socket}, 0)
    {:noreply, nil}
  end
end
