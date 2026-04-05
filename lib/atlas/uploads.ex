defmodule Atlas.Uploads do
  @moduledoc false

  def presign_upload(filename, content_type, size, community \\ nil) do
    config = Application.fetch_env!(:atlas, :uploads)

    with :ok <- validate_content_type(content_type, config[:allowed_types]),
         :ok <- validate_size(size, config[:max_size]) do
      key = generate_key(filename, community)
      bucket = config[:bucket]
      s3_endpoint = config[:s3_endpoint]

      presigned_url =
        presign_put_url(
          s3_endpoint,
          bucket,
          key,
          content_type,
          config[:access_key_id],
          config[:secret_access_key],
          config[:region]
        )

      public_url = "#{config[:public_url]}/#{bucket}/#{key}"

      {:ok, %{presigned_url: presigned_url, public_url: public_url}}
    end
  end

  defp presign_put_url(
         endpoint,
         bucket,
         key,
         content_type,
         access_key_id,
         secret_access_key,
         region
       ) do
    now = DateTime.utc_now()
    date = Calendar.strftime(now, "%Y%m%d")
    datetime = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")
    expires = 300

    uri = URI.parse("#{endpoint}/#{bucket}/#{key}")
    host = uri.host
    path = uri.path

    credential = "#{access_key_id}/#{date}/#{region}/s3/aws4_request"

    query_params =
      URI.encode_query(
        [
          {"X-Amz-Algorithm", "AWS4-HMAC-SHA256"},
          {"X-Amz-Credential", credential},
          {"X-Amz-Date", datetime},
          {"X-Amz-Expires", to_string(expires)},
          {"X-Amz-SignedHeaders", "content-type;host"}
        ],
        :rfc3986
      )

    canonical_request =
      Enum.join(
        [
          "PUT",
          path,
          query_params,
          "content-type:#{content_type}\nhost:#{host}\n",
          "content-type;host",
          "UNSIGNED-PAYLOAD"
        ],
        "\n"
      )

    string_to_sign =
      Enum.join(
        [
          "AWS4-HMAC-SHA256",
          datetime,
          "#{date}/#{region}/s3/aws4_request",
          sha256_hex(canonical_request)
        ],
        "\n"
      )

    signature =
      ("AWS4" <> secret_access_key)
      |> hmac_sha256(date)
      |> hmac_sha256(region)
      |> hmac_sha256("s3")
      |> hmac_sha256("aws4_request")
      |> hmac_sha256_hex(string_to_sign)

    "#{uri.scheme}://#{host}#{path}?#{query_params}&X-Amz-Signature=#{signature}"
  end

  defp validate_content_type(content_type, allowed_types) do
    if content_type in allowed_types,
      do: :ok,
      else: {:error, :invalid_content_type}
  end

  defp validate_size(size, max_size) do
    if size <= max_size,
      do: :ok,
      else: {:error, :file_too_large}
  end

  defp generate_key(filename, nil) do
    uuid = Ecto.UUID.generate()
    sanitized = sanitize_filename(filename)
    "#{uuid}/#{sanitized}"
  end

  defp generate_key(filename, community) do
    uuid = Ecto.UUID.generate()
    sanitized = sanitize_filename(filename)
    "#{community}/#{uuid}/#{sanitized}"
  end

  defp sanitize_filename(filename) do
    sanitized =
      filename
      |> String.replace(~r/[^\w.\-]/, "_")
      |> String.slice(0, 100)
      |> String.trim_leading(".")

    if sanitized == "", do: "upload", else: sanitized
  end

  defp hmac_sha256(key, data), do: :crypto.mac(:hmac, :sha256, key, data)
  defp hmac_sha256_hex(key, data), do: hmac_sha256(key, data) |> Base.encode16(case: :lower)
  defp sha256_hex(data), do: :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
end
