defmodule RetryDemo.UploadServer.Supervisor do
  @moduledoc """
  `DyanmicSupervisor` for `RetryDemo.UploadServer` processes.
  """

  def child_spec() do
    {DynamicSupervisor, strategy: :one_for_one, name: __MODULE__}
  end
end

defmodule RetryDemo.UploadServer do
  use GenServer

  @supervisor RetryDemo.UploadServer.Supervisor

  @typedoc "Path to file"
  @type file :: String.t()

  @doc "Upload a file"
  @spec upload(file) :: :ok
  def upload(file) do
    DynamicSupervisor.start_child(@supervisor, child_spec(file))
  end

  @doc false
  def child_spec(file) do
    %{
      id: file,
      restart: :temporary,
      start: {__MODULE__, :start_link, [file]}
    }
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  @impl GenServer
  def init(file) do
    state = %{
      retries: 0,
      max_retries: 5,
      file: file
    }
    send(self(), :perform_upload)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:perform_upload, state) do
    case perform_upload(state.file) do
      :ok ->
        {:stop, :normal, state}

      {:error, _reason} ->
        # TODO retry upload
        {:noreply, state}
    end
  end

  @doc false
  @spec perform_upload(file) :: :ok | {:error, reason :: String.t()}
  def perform_upload(file) do
    IO.write("Uploading #{file}...")
    Process.sleep(1000)
    IO.puts("\t DONE!")
    :ok
  end
end
