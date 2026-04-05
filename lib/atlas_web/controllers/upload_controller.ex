defmodule AtlasWeb.UploadController do
  use AtlasWeb, :controller

  alias Atlas.Uploads

  def presign(conn, %{"filename" => filename, "content_type" => content_type, "size" => size} = params)
      when is_binary(filename) and is_binary(content_type) do
    community = params["community"]

    with {:ok, size} <- parse_size(size),
         {:ok, result} <- Uploads.presign_upload(filename, content_type, size, community) do
      json(conn, %{presigned_url: result.presigned_url, public_url: result.public_url})
    else
      {:error, :invalid_size} ->
        conn |> put_status(422) |> json(%{error: "Invalid file size"})

      {:error, :invalid_content_type} ->
        conn |> put_status(422) |> json(%{error: "Invalid file type"})

      {:error, :file_too_large} ->
        conn |> put_status(422) |> json(%{error: "File too large (max 10MB)"})
    end
  end

  def presign(conn, _params) do
    conn
    |> put_status(422)
    |> json(%{error: "Missing required fields: filename, content_type, size"})
  end

  defp parse_size(size) when is_integer(size) and size > 0, do: {:ok, size}

  defp parse_size(size) when is_binary(size) do
    case Integer.parse(size) do
      {n, ""} when n > 0 -> {:ok, n}
      _ -> {:error, :invalid_size}
    end
  end

  defp parse_size(_), do: {:error, :invalid_size}
end
