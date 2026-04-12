import { createRoot } from "react-dom/client"
import { createElement, useRef, useCallback, useState, useEffect } from "react"
import { BlockNoteView } from "@blocknote/mantine"
import { createReactBlockSpec, useCreateBlockNote } from "@blocknote/react"
import { BlockNoteSchema, defaultBlockSpecs, defaultInlineContentSpecs, defaultStyleSpecs, filterSuggestionItems } from "@blocknote/core"
import { getDefaultReactSlashMenuItems, SuggestionMenuController } from "@blocknote/react"
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

function parseYouTubeUrl(url) {
  if (!url) return null
  try {
    const u = new URL(url)
    if (u.hostname === "youtu.be") {
      return u.pathname.slice(1)
    }
    if (u.hostname === "www.youtube.com" || u.hostname === "youtube.com") {
      if (u.pathname === "/watch") {
        return u.searchParams.get("v")
      }
      const embedMatch = u.pathname.match(/^\/embed\/(.+)/)
      if (embedMatch) return embedMatch[1]
      const shortsMatch = u.pathname.match(/^\/shorts\/(.+)/)
      if (shortsMatch) return shortsMatch[1]
    }
  } catch {
    return null
  }
  return null
}

const YouTube = createReactBlockSpec(
  {
    type: "youtube",
    propSchema: {
      url: { default: "" },
    },
    content: "none",
  },
  {
    render: (props) => {
      const [inputUrl, setInputUrl] = useState(props.block.props.url || "")
      const videoId = parseYouTubeUrl(props.block.props.url)

      if (videoId) {
        return createElement("div", {
          className: "youtube-embed",
          style: { width: "100%", aspectRatio: "16/9", borderRadius: "8px", overflow: "hidden", marginBottom: "4px" },
        },
          createElement("iframe", {
            src: `https://www.youtube-nocookie.com/embed/${videoId}`,
            style: { width: "100%", height: "100%", border: "none" },
            allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture",
            allowFullScreen: true,
          })
        )
      }

      return createElement("div", {
        style: {
          display: "flex",
          flexDirection: "column",
          gap: "8px",
          padding: "16px",
          border: "1px dashed oklch(var(--bc) / 0.3)",
          borderRadius: "8px",
          background: "oklch(var(--b2))",
        }
      },
        createElement("div", { style: { display: "flex", alignItems: "center", gap: "8px", color: "oklch(var(--bc) / 0.6)", fontSize: "14px" } },
          createElement("svg", { width: 20, height: 20, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round", strokeLinejoin: "round" },
            createElement("path", { d: "M2.5 17a24.12 24.12 0 0 1 0-10 2 2 0 0 1 1.4-1.4 49.56 49.56 0 0 1 16.2 0A2 2 0 0 1 21.5 7a24.12 24.12 0 0 1 0 10 2 2 0 0 1-1.4 1.4 49.55 49.55 0 0 1-16.2 0A2 2 0 0 1 2.5 17" }),
            createElement("path", { d: "m10 15 5-3-5-3z" })
          ),
          "YouTube Video"
        ),
        createElement("div", { style: { display: "flex", gap: "8px" } },
          createElement("input", {
            type: "text",
            placeholder: "Paste YouTube URL...",
            value: inputUrl,
            onChange: (e) => setInputUrl(e.target.value),
            onKeyDown: (e) => {
              if (e.key === "Enter") {
                e.preventDefault()
                const id = parseYouTubeUrl(inputUrl)
                if (id) {
                  props.editor.updateBlock(props.block, {
                    props: { url: inputUrl.trim() },
                  })
                }
              }
            },
            style: {
              flex: 1,
              padding: "6px 10px",
              border: "1px solid oklch(var(--bc) / 0.2)",
              borderRadius: "6px",
              background: "oklch(var(--b1))",
              color: "oklch(var(--bc))",
              fontSize: "14px",
              outline: "none",
            },
          }),
          createElement("button", {
            onClick: () => {
              const id = parseYouTubeUrl(inputUrl)
              if (id) {
                props.editor.updateBlock(props.block, {
                  props: { url: inputUrl.trim() },
                })
              }
            },
            style: {
              padding: "6px 14px",
              borderRadius: "6px",
              border: "none",
              background: "oklch(var(--p))",
              color: "oklch(var(--pc))",
              cursor: "pointer",
              fontSize: "14px",
              fontWeight: 500,
            },
          }, "Embed")
        )
      )
    },
  }
)

const { video, audio, file, ...restBlockSpecs } = defaultBlockSpecs

const schema = BlockNoteSchema.create({
  blockSpecs: {
    ...restBlockSpecs,
    youtube: YouTube(),
  },
  inlineContentSpecs: defaultInlineContentSpecs,
  styleSpecs: defaultStyleSpecs,
})

function getCustomSlashMenuItems(editor) {
  return [
    ...getDefaultReactSlashMenuItems(editor),
    {
      title: "YouTube Video",
      subtext: "Embed a YouTube video",
      group: "Media",
      icon: createElement("svg", { width: 18, height: 18, viewBox: "0 0 24 24", fill: "currentColor" },
        createElement("path", { d: "M21.543 6.498C22 8.28 22 12 22 12s0 3.72-.457 5.502c-.254.985-.997 1.76-1.938 2.022C17.896 20 12 20 12 20s-5.893 0-7.605-.476c-.945-.266-1.687-1.04-1.938-2.022C2 15.72 2 12 2 12s0-3.72.457-5.502c.254-.985.997-1.76 1.938-2.022C6.107 4 12 4 12 4s5.896 0 7.605.476c.945.266 1.687 1.04 1.938 2.022ZM10 15.5l6-3.5-6-3.5v7Z" })
      ),
      onItemClick: () => {
        editor.insertBlocks(
          [{ type: "youtube" }],
          editor.getTextCursorPosition().block,
          "after"
        )
      },
      aliases: ["youtube", "video", "yt"],
    },
  ]
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
    schema,
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
    slashMenu: false,
  },
    createElement(SuggestionMenuController, {
      triggerCharacter: "/",
      getItems: async (query) => {
        const filtered = filterSuggestionItems(getCustomSlashMenuItems(editor), query)
        filtered.sort((a, b) => (a.group || "").localeCompare(b.group || ""))
        return filtered
      },
    })
  )
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
