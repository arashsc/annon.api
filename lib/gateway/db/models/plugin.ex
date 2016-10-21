defmodule Gateway.DB.Models.Plugin do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :model
  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  @derive {Poison.Encoder, except: [:__meta__, :api]}

  schema "plugins" do
     field :name, PluginName
     field :is_enabled, :boolean, default: false
     field :settings, :map
     belongs_to :api, APIModel

     timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :settings, :is_enabled])
    |> assoc_constraint(:api)
    |> unique_constraint(:api_id_name)
    |> validate_required([:name, :settings])
    |> prepare_name
    |> validate_map(:settings)
  end

  def prepare_name(%Ecto.Changeset{} = changeset) do
    changeset
    |> fetch_field(:name)
    |> capitalize_name
    |> put_name(changeset)
  end

  def capitalize_name({:changes, name}) when is_binary(name), do: String.capitalize(name)
  def capitalize_name(_), do: nil

  def put_name(nil, changeset), do: changeset
  def put_name(name, %Ecto.Changeset{} = changeset) when is_binary(name) do
    changeset
    |> put_change(:name, name)
  end

  def create(nil, _params), do: nil
  def create(%APIModel{} = api, params) when is_map(params) do
    api
    |> Ecto.build_assoc(:plugins)
    |> Plugin.changeset(params)
    |> Repo.insert
  end

  def update(api_id, name, params) when is_map(params) do
    %Plugin{}
    |> Plugin.changeset(params)
    |> update_plugin(api_id, name)
    |> normalize_ecto_update_resp
  end
  defp update_plugin(%Ecto.Changeset{valid?: true, changes: changes}, api_id, name) do
    query = from(p in Plugin, where: p.api_id == ^api_id, where: p.name == ^name)
    Repo.update_all(query, [set: Map.to_list(changes)], returning: true)
  end
  defp update_plugin(%Ecto.Changeset{valid?: false} = ch, _api_id, _name), do: {:error, ch}

  def delete(api_id, name) do
    query = from p in Plugin,
            where: p.api_id == ^api_id,
            where: p.name == ^name
    query
    |> Repo.delete_all
    |> normalize_ecto_delete_resp
  end

  defp normalize_ecto_delete_resp({0, _}), do: nil
  defp normalize_ecto_delete_resp({1, _}), do: {:ok, nil}

  defp normalize_ecto_update_resp({0, _}), do: nil
  defp normalize_ecto_update_resp({1, [struct]}), do: struct
  defp normalize_ecto_update_resp({:error, ch}), do: {:error, ch}
end