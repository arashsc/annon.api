defmodule Gateway.Plugins.Consumers do
  @moduledoc """
  This plugin reads consumer settings.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "consumers"

  import Ecto.Query, only: [from: 2]

  alias Plug.Conn
  alias Joken.Token
  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Consumer
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema

  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  def merge_consumer_settings(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn,
                              %Token{claims: %{"id" => id}}) do
    id
    |> get_consumer_settings()
    |> merge_plugins(plugins)
    |> put_api_to_conn(conn)
  end
  def merge_consumer_settings(conn, _token), do: conn

  # TODO: Read if from cache
  def get_consumer_settings(external_id) do
    Repo.all from c in Consumer,
      where: c.external_id == ^external_id,
      join: s in assoc(c, :plugins),
      where: s.is_enabled == true,
      select: {s.plugin_id, s.settings}
  end

  def merge_plugins(consumer, default)
      when is_list(consumer) and length(consumer) > 0 and is_list(default) and length(default) > 0 do
    default
    |> Enum.map_reduce([], fn(d_plugin, acc) ->
      mergerd_plugin = consumer
      |> Enum.filter(fn({c_id, _}) -> c_id == d_plugin.id end)
      |> merge_plugin(d_plugin)

      {nil, List.insert_at(acc, -1, mergerd_plugin)}
    end)
    |> elem(1)
  end
  def merge_plugins(_consumer, _default), do: nil

  def merge_plugin([{_, consumer_settings}], %Plugin{} = plugin) do
    plugin
    |> Map.merge(%{settings: consumer_settings, is_enabled: true})
  end
  def merge_plugin(_, plugin), do: plugin

  def put_api_to_conn(nil, conn), do: conn
  def put_api_to_conn(plugins, %Conn{private: %{api_config: %APISchema{} = api}} = conn) when is_list(plugins) do
    conn
    |> Conn.put_private(:api_config, Map.put(api, :plugins, plugins))
  end

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: _settings}, %Conn{private: %{jwt_token: token}} = conn) do
    conn
    |> merge_consumer_settings(token)
  end
end