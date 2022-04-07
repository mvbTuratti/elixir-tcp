defmodule TcpServer.Command do

  def parse(line) do
    [command | _remainder] = String.split(line, "\r\n")
    case String.split(command) do
      ["GET", file, _protocol] -> {:ok, {:get, file}}
      _ -> {:error, :unknown_command}
    end
  end

  def run({:get, file}) do
    [extension| _] = Regex.run(~r/\w*$/,file)
    {_, path} = File.cwd()
    File.read(path <> "/templates" <> file)
    |> get(extension)
  end

  def run(_todo) do
    #other CRUD todo.
  end

  defp get({:ok, body}, "html") do
    response = "HTTP/1.0 200 OK\nContent-Type: text/html\nContent-Length: #{:erlang.size(body)}\n\n#{body}"
    {:ok, response}
  end

  defp get({:ok, body}, "css") do
    response = "HTTP/1.0 200 OK\nContent-Type: text/css\nContent-Length: #{:erlang.size(body)}\n\n#{body}"
    {:ok, response}
  end

  defp get({:ok, body}, "jpeg") do
    response = "HTTP/1.0 200 OK\nContent-Type: image/jpeg\nContent-Length: #{:erlang.size(body)}\n\n#{body}"
    {:ok, response}
  end



  defp get({:error, _reason}, _) do
    html = "<html><head><title>Not Found</title></head><body>Not Found</body></html>"
    response = "HTTP/1.0 404 Not Found\nContent-Type: text/html\nContent-Length: #{:erlang.size(html)}\n\n#{html}"
    {:ok, response}
  end
end
