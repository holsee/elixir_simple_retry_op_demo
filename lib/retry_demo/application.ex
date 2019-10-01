defmodule RetryDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RetryDemo.UploadServer

  def start(_type, _args) do
    children = [
      UploadServer.Supervisor.child_spec()
    ]

    opts = [strategy: :one_for_one, name: RetryDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
