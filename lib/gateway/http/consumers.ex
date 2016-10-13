defmodule Gateway.HTTP.Consumers do
  @moduledoc """
  REST for Consumers
  Documentation http://docs.osapigateway.apiary.io/#reference/consumers
  """
  use Gateway.Helpers.CommonRouter

  get "/" do
    Gateway.DB.Consumer
    |> Gateway.DB.Repo.all
    |> render_show_response
    |> send_response(conn)
  end

  get "/:consumer_id" do
    Gateway.DB.Consumer
    |> Gateway.DB.Repo.get(consumer_id)
    |> render_show_response
    |> send_response(conn)
  end

  put "/:consumer_id" do
    consumer_id
    |> Gateway.DB.Consumer.update(conn.body_params)
    |> render_show_response
    |> send_response(conn)
  end

  post "/" do
    conn.body_params
    |> Gateway.DB.Consumer.create
    |> render_create_response
    |> send_response(conn)
  end

  delete "/:consumer_id" do
    consumer_id
    |> Gateway.DB.Consumer.delete
    |> render_delete_response
    |> send_response(conn)
  end

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end