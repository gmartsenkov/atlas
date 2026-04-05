// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/atlas"
import BlockEditor from "./hooks/block_editor.jsx"
import LogoUpload from "./hooks/logo_upload.js"
import Sortable from "sortablejs"
import topbar from "../vendor/topbar"

const ScrollTo = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const anchor = e.target.closest("a[href^='#']")
      if (!anchor) return
      e.preventDefault()
      const id = anchor.getAttribute("href").slice(1)
      const target = document.getElementById(id)
      if (!target) return
      const scrollable = target.closest(".overflow-y-auto")
      if (scrollable) {
        const targetRect = target.getBoundingClientRect()
        const scrollableRect = scrollable.getBoundingClientRect()
        const top = scrollable.scrollTop + targetRect.top - scrollableRect.top
        scrollable.scrollTo({ top, behavior: "smooth" })
      } else {
        target.scrollIntoView({ behavior: "smooth", block: "start" })
      }
      const url = new URL(window.location)
      url.searchParams.set("scroll_to", id)
      history.replaceState(history.state, "", url)
      if (window.innerWidth < 1024) this.pushEvent("toggle_sidebar", {})
    })
  }
}

const ScrollIntoView = {
  mounted() {
    this.el.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}

const ScrollToTarget = {
  mounted() {
    this.handleEvent("scroll-to", ({ id }) => {
      requestAnimationFrame(() => {
        const target = document.getElementById(id)
        if (!target) return
        const rect = target.getBoundingClientRect()
        const scrollableRect = this.el.getBoundingClientRect()
        const top = this.el.scrollTop + rect.top - scrollableRect.top
        this.el.scrollTo({ top, behavior: "smooth" })
      })
    })

    this.handleEvent("scroll-top", () => {
      this.el.scrollTo({ top: 0 })
    })

    this._setupObserver()
  },
  updated() {
    this._setupObserver()
  },
  destroyed() {
    if (this._observer) this._observer.disconnect()
    if (this._onScroll) this.el.removeEventListener("scroll", this._onScroll)
  },
  _setupObserver() {
    if (this._observer) this._observer.disconnect()
    if (this._onScroll) this.el.removeEventListener("scroll", this._onScroll)

    const headings = this.el.querySelectorAll("h1[id], h2[id], h3[id], h4[id]")
    if (!headings.length) return

    const visibleIds = new Set()
    let lastActiveId = null

    const highlight = () => {
      const el = this.el
      const atBottom = Math.abs(el.scrollHeight - el.scrollTop - el.clientHeight) < 2

      let activeId = null
      if (atBottom) {
        activeId = headings[headings.length - 1].id
      } else {
        for (const h of headings) {
          if (visibleIds.has(h.id)) { activeId = h.id; break }
        }
      }

      if (activeId === lastActiveId) return
      lastActiveId = activeId

      const nav = document.getElementById("sections-nav")
      if (!nav) return
      nav.querySelectorAll("a[href^='#']").forEach((a) => {
        const id = a.getAttribute("href").slice(1)
        if (id === activeId) {
          a.classList.add("!text-base-content", "font-medium")
        } else {
          a.classList.remove("!text-base-content", "font-medium")
        }
      })
    }

    this._observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            visibleIds.add(entry.target.id)
          } else {
            visibleIds.delete(entry.target.id)
          }
        })
        highlight()
      },
      { root: this.el, rootMargin: "0px 0px -70% 0px", threshold: 0 }
    )

    headings.forEach((h) => this._observer.observe(h))

    this._onScroll = () => highlight()
    this.el.addEventListener("scroll", this._onScroll, { passive: true })
  }
}

const AutoDismiss = {
  mounted() {
    this.timer = setTimeout(() => {
      this.el.style.opacity = "0"
      setTimeout(() => this.el.remove(), 700)
    }, 4000)
  },
  destroyed() {
    clearTimeout(this.timer)
  }
}

const SortableHook = {
  mounted() { this._init() },
  destroyed() { this._destroy() },
  _init() {
    const event = this.el.dataset.sortableEvent
    this._sortable = Sortable.create(this.el, {
      animation: 150,
      ghostClass: "opacity-30",
      handle: "[data-drag-handle]",
      onEnd: () => {
        const ids = Array.from(this.el.children).map(el => el.dataset.sortableId).filter(Boolean)
        this.pushEvent(event, { ids })
      }
    })
  },
  _destroy() { if (this._sortable) this._sortable.destroy() }
}

const PageDragHook = {
  mounted() { this._init() },
  destroyed() { this._destroy() },
  _init() {
    this._sortable = Sortable.create(this.el, {
      group: "pages",
      animation: 150,
      ghostClass: "opacity-30",
      onEnd: (evt) => {
        const ids = Array.from(evt.to.children).map(el => el.dataset.pageId).filter(Boolean)
        if (evt.from !== evt.to) {
          const pageId = evt.item.dataset.pageId
          const toCollectionId = evt.to.dataset.collectionId || ""
          this.pushEvent("move-page", { "page-id": pageId, "collection-id": toCollectionId, "ids": ids })
        } else {
          this.pushEvent("reorder-pages", { "ids": ids })
        }
      }
    })
  },
  _destroy() { if (this._sortable) this._sortable.destroy() }
}

const EditorScroll = {
  mounted() {
    this.handleEvent("editor-scroll-to", ({ id }) => {
      requestAnimationFrame(() => {
        const target = this.el.querySelector(`[data-id="${id}"]`)
        if (!target) return
        const rect = target.getBoundingClientRect()
        const containerRect = this.el.getBoundingClientRect()
        const top = this.el.scrollTop + rect.top - containerRect.top
        this.el.scrollTo({ top, behavior: "smooth" })
      })
    })
  }
}

const Hooks = { ...colocatedHooks, BlockEditor, LogoUpload, ScrollTo, ScrollIntoView, ScrollToTarget, AutoDismiss, SortableHook, PageDragHook, EditorScroll }

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

