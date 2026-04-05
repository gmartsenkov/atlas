import { createRoot } from "react-dom/client"
import { createElement, useRef, useCallback, useState, useEffect } from "react"
import { BlockNoteView } from "@blocknote/mantine"
import { useCreateBlockNote } from "@blocknote/react"
import "@blocknote/mantine/style.css"

function getTheme() {
  const explicit = document.documentElement.getAttribute("data-theme")
  if (explicit) return explicit === "dark" ? "dark" : "light"
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
}

function useTheme() {
  const [theme, setTheme] = useState(getTheme)

  useEffect(() => {
    const update = () => setTheme(getTheme())

    const observer = new MutationObserver(update)
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] })

    const mql = window.matchMedia("(prefers-color-scheme: dark)")
    mql.addEventListener("change", update)

    return () => {
      observer.disconnect()
      mql.removeEventListener("change", update)
    }
  }, [])

  return theme
}

async function uploadFile(file, community) {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

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
      community,
    }),
  })

  if (!resp.ok) {
    const body = await resp.json()
    throw new Error(body.error || "Upload failed")
  }

  const { presigned_url, public_url } = await resp.json()

  const putResp = await fetch(presigned_url, {
    method: "PUT",
    headers: { "Content-Type": file.type },
    body: file,
  })

  if (!putResp.ok) {
    throw new Error("Failed to upload file to storage")
  }

  return public_url
}

function Editor({ initialContent, onChange, community }) {
  const theme = useTheme()
  const editor = useCreateBlockNote({
    initialContent: initialContent && initialContent.length > 0 ? initialContent : undefined,
    uploadFile: (file) => uploadFile(file, community),
  })

  const handleChange = useCallback(() => {
    const blocks = editor.document
    onChange(blocks)
  }, [editor, onChange])

  return createElement(BlockNoteView, {
    editor,
    onChange: handleChange,
    theme,
  })
}

const BlockEditor = {
  mounted() {
    const hook = this
    const sectionId = this.el.dataset.sectionId
    const community = this.el.dataset.community

    // Parse initial content from the server
    let initialContent = []
    try {
      const raw = this.el.dataset.content
      if (raw) {
        initialContent = JSON.parse(raw)
      }
    } catch (e) {
      console.warn("Failed to parse initial content:", e)
    }

    const root = createRoot(this.el)
    root.render(
      createElement(Editor, {
        initialContent,
        community,
        onChange: (blocks) => {
          const payload = { blocks }
          if (sectionId) {
            payload.section_id = sectionId
          }
          hook.pushEvent("editor-updated", payload)
        },
      })
    )

    this._root = root
  },

  destroyed() {
    if (this._root) {
      this._root.unmount()
    }
  },
}

export default BlockEditor
