defmodule Annon.Plugins.Auth do
  @moduledoc """
  This plugin authenticates API consumers by using a configured strategy.
  """
  use Annon.Plugin, plugin_name: :auth
  alias Annon.Helpers.Response
  alias EView.Views.Error, as: ErrorView
  alias Plug.Conn
  alias Annon.Plugin.UpstreamRequest

  defdelegate validate_settings(changeset), to: Annon.Plugins.Auth.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.Auth.SettingsValidator

  @strategies %{
    "jwt" => Annon.Plugins.Auth.Strategies.JWT,
    "oauth" => Annon.Plugins.Auth.Strategies.OAuth
  }

  def execute(%Conn{halted: true} = conn, _request, _settings),
    do: conn
  def execute(%Conn{} = conn, _request, %{"strategy" => strategy} = settings) do
    adapter = Map.fetch!(@strategies, strategy)

    with {:ok, token_type, token} <- fetch_authorization(conn),
         {:ok, consumer} <- adapter.fetch_consumer(token_type, token, settings) do
      conn
      |> Conn.assign(:consumer, consumer)
      |> put_x_consumer_id_header(consumer.id)
      |> put_x_consumer_scope_header(consumer.scope)
    else
      :error -> send_unathorized(conn, "Authorization header is not set or doesn't contain Bearer token")
      {:error, message} -> send_unathorized(conn, message)
    end
  end

  defp fetch_authorization(conn) do
    case Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> {:ok, :bearer, token}
      _ -> :error
    end
  end

  defp put_x_consumer_scope_header(%Conn{assigns: %{upstream_request: upstream_request}} = conn, consumer_scope) do
    upstream_request = UpstreamRequest.put_header(upstream_request, "x-consumer-scope", consumer_scope)
    Conn.assign(conn, :upstream_request, upstream_request)
  end

  defp put_x_consumer_id_header(%Conn{assigns: %{upstream_request: upstream_request}} = conn, consumer_id) do
    upstream_request = UpstreamRequest.put_header(upstream_request, "x-consumer-id", consumer_id)
    Conn.assign(conn, :upstream_request, upstream_request)
  end

  defp send_unathorized(conn, message) do
    "401.json"
    |> ErrorView.render(%{
      message: message,
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        description: message,
        rules: []
      }]
    })
    |> Response.send(conn, 401)
    |> Response.halt()
  end
end
