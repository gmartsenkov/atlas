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

function Editor({ initialContent, onChange }) {
  const theme = useTheme()
  const editor = useCreateBlockNote({
    initialContent: initialContent && initialContent.length > 0 ? initialContent : undefined,
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
        onChange: (blocks) => {
          hook.pushEvent("editor-updated", { blocks })
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
