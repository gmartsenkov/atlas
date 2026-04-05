const MAX_SIZE = 1 * 1024 * 1024 // 1MB

const LogoUpload = {
  mounted() {
    const input = this.el.querySelector("input[type=file]")

    this.el.addEventListener("click", (e) => {
      if (e.target.closest("[data-remove-logo]")) return
      input.click()
    })

    input.addEventListener("change", async (e) => {
      const file = e.target.files[0]
      if (!file) return

      if (!file.type.startsWith("image/")) {
        alert("Please select an image file.")
        input.value = ""
        return
      }

      if (file.size > MAX_SIZE) {
        alert("Image must be under 1MB.")
        input.value = ""
        return
      }

      try {
        this.el.setAttribute("data-uploading", "true")

        const csrfToken = document
          .querySelector("meta[name='csrf-token']")
          ?.getAttribute("content")

        const resp = await fetch("/api/uploads/presign", {
          method: "POST",
          headers: {
            "content-type": "application/json",
            "x-csrf-token": csrfToken,
          },
          body: JSON.stringify({
            filename: file.name,
            content_type: file.type,
            size: file.size,
            community: "logos",
          }),
        })

        if (!resp.ok) {
          const body = await resp.json()
          throw new Error(body.error || "Presign failed")
        }

        const { presigned_url, public_url } = await resp.json()

        const putResp = await fetch(presigned_url, {
          method: "PUT",
          headers: { "Content-Type": file.type },
          body: file,
        })

        if (!putResp.ok) throw new Error("Upload failed")

        this.pushEvent("logo-uploaded", { url: public_url })
      } catch (err) {
        console.error("Logo upload error:", err)
        alert("Upload failed. Please try again.")
      } finally {
        this.el.removeAttribute("data-uploading")
        input.value = ""
      }
    })
  },
}

export default LogoUpload
