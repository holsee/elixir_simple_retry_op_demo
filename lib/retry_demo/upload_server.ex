defmodule RetryDemo.UploadServer.Supervisor do
  @moduledoc """
  `DyanmicSupervisor` for `RetryDemo.UploadServer` processes.
  """

  def child_spec() do
    {DynamicSupervisor, strategy: :one_for_one, name: __MODULE__}
  end
end

defmodule RetryDemo.UploadServer do
  @moduledoc """
  A dummy uploader process, with simple retry logic, which terminates upon completion.
  """
  use GenServer

  @supervisor RetryDemo.UploadServer.Supervisor

  @typedoc "Path to file"
  @type file :: String.t()

  @typep reason :: String.t()
  @typep state :: %{
           required(:file) => String.t(),
           required(:retry_count) => non_neg_integer(),
           required(:retry_max) => pos_integer(),
           required(:retry_delay_ms) => pos_integer()
         }

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

  @default_retry_max 5
  @default_retry_delay_ms 1000

  @impl GenServer
  def init(file) do
    state = %{
      retry_count: 0,
      retry_max: @default_retry_max,
      retry_delay_ms: @default_retry_delay_ms,
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
        case retry_upload(state) do
          {:ok, state} ->
            {:noreply, state}

          {:error, reason} ->
            IO.puts("Terminating with failure: #{reason}")
            {:stop, :normal, state}
        end
    end
  end

  @doc false
  @spec perform_upload(file) :: :ok | {:error, reason}
  def perform_upload(file) do
    IO.write("Uploading #{file}...")
    Process.sleep(1000)

    # Some dummy logic to fail when file ends with .fail
    cond do
      String.ends_with?(file, ".fail") ->
        IO.puts("FAILED!!")
        {:error, "Upload failed!!"}

      true ->
        IO.puts("\t DONE!")
        :ok
    end
  end

  @doc false
  @spec retry_upload(state) :: {:ok, state} | {:error, reason}
  def retry_upload(state) do
    IO.inspect(state)

    case state do
      %{retry_count: count, retry_max: count} ->
        {:error, "Failed after #{count} retries."}

      %{retry_count: count, retry_max: max} when count < max ->
        # This is where you can select your retry strategy
        Process.send_after(self(), :perform_upload, state.retry_delay_ms)
        {:ok, %{state | retry_count: count + 1}}
    end
  end
end
