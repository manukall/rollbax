Logger.configure(level: :info)
Application.ensure_all_started(:hackney)
ExUnit.start()

defmodule ExUnit.RollbaxCase do
  use ExUnit.CaseTemplate

  using(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def start_rollbax_client(token, envt) do
    Rollbax.Client.start_link(token, envt, true, "http://localhost:4004")
  end

  def capture_log(fun) do
    ExUnit.CaptureIO.capture_io(:user, fn ->
      fun.()
      :timer.sleep(100)
      Logger.flush()
    end)
  end
end

defmodule RollbarAPI do
  alias Plug.Conn
  alias Plug.Adapters.Cowboy

  import Conn

  def start(pid) do
    Cowboy.http(__MODULE__, [test: pid], port: 4004)
  end

  def stop() do
    :timer.sleep(80)
    Cowboy.shutdown(__MODULE__.HTTP)
  end

  def init(opts) do
    Keyword.fetch!(opts, :test)
  end

  def call(%Conn{method: "POST"} = conn, test) do
    {:ok, body, conn} = read_body(conn)
    :timer.sleep(30)
    send test, {:api_request, body}
    send_resp(conn, 200, "OK")
  end

  def call(conn, _test) do
    send_resp(conn, 404, "Not Found")
  end
end
