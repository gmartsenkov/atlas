import { createRoot } from "react-dom/client"
import { createElement, useRef, useCallback } from "react"
import { BlockNoteView } from "@blocknote/mantine"
import { useCreateBlockNote } from "@blocknote/react"
import "@blocknote/mantine/style.css"

function Editor({ initialContent, onChange }) {
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
    theme: "light",
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
