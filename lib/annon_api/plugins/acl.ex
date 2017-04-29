defmodule Annon.Plugins.ACL do
  @moduledoc """
  [Access Control Layer (ACL) plugin](http://docs.annon.apiary.io/#reference/plugins/acl).

  It allows to set list of scopes that is required for path relative to an API.
  """
  use Annon.Helpers.Plugin,
    plugin_name: "acl"

  alias Plug.Conn
  alias Annon.DB.Schemas.Plugin
  alias Annon.DB.Schemas.API, as: APISchema
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response

  @doc false
  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins, request: %{path: api_path}}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(api_path, conn)
    |> send_response(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, _api_path, _conn), do: :ok
  defp execute(%Plugin{settings: %{"rules" => rules}},
               api_path,
               %Conn{private: %{scopes: scopes}} = conn) do
    scopes
    |> validate_scopes(rules, api_path, Map.take(conn, [:request_path, :method]))
  end
  defp execute(%Plugin{settings: %{"rules" => _}}, _api_path, _conn), do: {:error, :no_scopes_is_set}
  defp execute(_plugin, _api_path, _conn), do: :ok

  defp validate_scopes(nil, _server_rules, _api_path, _conn_data),
    do: {:error, :no_scopes_is_set}
  defp validate_scopes(client_scopes, server_rules, api_path, conn_data) when is_list(client_scopes) do
    request_path = String.trim_leading(conn_data.request_path, api_path)

    matching_fun = fn server_rules ->
      method_matches? = conn_data.method in server_rules["methods"]
      path_matches? = request_path =~ ~r"#{server_rules["path"]}"

      method_matches? && path_matches?
    end

    result_fun = fn server_rules ->
      Enum.filter(server_rules["scopes"], fn(server_scope) -> !(server_scope in client_scopes) end)
    end

    missing_scopes_result = Enum.filter_map(server_rules, matching_fun, result_fun)
    case Enum.any?(missing_scopes_result, fn(x) -> x == [] end) do
      true -> :ok
      false -> {:error, :forbidden, missing_scopes_result |> Enum.find(fn(x) -> x != [] end) |> Enum.at(0)}
    end
  end
  defp validate_scopes(_client_scope, _server_rules, _api_path, _conn_data), do: {:error, :invalid_scopes_type}

  defp get_scopes_message([] = missing_scopes) do
    "Your scopes does not allow to access this resource. Missing scopes: #{Enum.join(missing_scopes, ", ")}."
  end
  defp get_scopes_message(missing_scopes) do
    "Your scopes does not allow to access this resource. Missing scopes: #{missing_scopes}."
  end

  defp send_response(:ok, conn), do: conn
  defp send_response({:error, :forbidden, missing_scopes}, conn) do
    "403.json"
    |> ErrorView.render(%{
      message: get_scopes_message(missing_scopes),
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        rules: []
      }]
    })
    |> Response.send(conn, 403)
    |> Response.halt()
  end
  defp send_response({:error, :no_scopes_is_set}, conn) do
    Logger.error("Scopes are empty!")
    conn
    |> Response.send_error(:internal_error)
  end
  defp send_response({:error, :invalid_scopes_type}, conn) do
    Logger.error("Scopes must be a list!")
    conn
    |> Response.send_error(:internal_error)
  end
end