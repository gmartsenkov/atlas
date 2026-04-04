defmodule AtlasWeb.UploadController do
  use AtlasWeb, :controller

  alias Atlas.Uploads

  def presign(conn, %{"filename" => filename, "content_type" => content_type, "size" => size}) do
    size = if is_binary(size), do: String.to_integer(size), else: size

    case Uploads.presign_upload(filename, content_type, size) do
      {:ok, %{presigned_url: presigned_url, public_url: public_url}} ->
        json(conn, %{presigned_url: presigned_url, public_url: public_url})

      {:error, :invalid_content_type} ->
        conn |> put_status(422) |> json(%{error: "Invalid file type"})

      {:error, :file_too_large} ->
        conn |> put_status(422) |> json(%{error: "File too large (max 10MB)"})
    end
  end
end
