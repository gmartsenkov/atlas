# Security Audit Report — Atlas

**Date:** 2026-04-13
**Scope:** Full application pentest (Phoenix LiveView + Ecto + S3 uploads)
**Methodology:** Static analysis across 4 parallel audit domains: Auth/Session, Input Validation/XSS, Authorization/IDOR, File Uploads/Injection

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 3 |
| High | 6 |
| Medium | 10 |
| Low | 7 |
| Info | 10+ |

---

## Critical

### C1: IDOR on Report Resolution — Cross-Community Privilege Escalation

**Files:** `lib/atlas_web/live/dashboard_live.ex:182-214`

The `resolve-report`, `remove-reported-content`, and `redact-comment` event handlers fetch any report by ID globally (`Communities.get_report(id)`) without verifying:
1. The report belongs to `socket.assigns.selected_community`
2. The current user is a moderator of the report's community

A moderator in Community A can resolve reports, remove content, or redact comments in Community B by sending crafted report IDs.

**Fix:** Add `report.community_id == socket.assigns.selected_community.id` check before acting.

---

### C2: Session Cookie Not Encrypted — Token Readable by Client

**File:** `lib/atlas_web/endpoint.ex:7-12`

```elixir
@session_options [
  store: :cookie,
  key: "_atlas_key",
  signing_salt: "IRebiIu4",
  same_site: "Lax"
]
```

The session cookie is signed but not encrypted. The `user_token` (a raw 32-byte session token) is readable by any client-side JavaScript (if HttpOnly is ever missing) or via browser dev tools. The source code comments acknowledge this: "Set `:encryption_salt` if you would also like to encrypt it."

**Fix:** Add `encryption_salt` to `@session_options`.

---

### C3: Remember-Me Cookie Missing `secure: true` and `http_only: true`

**File:** `lib/atlas_web/user_auth.ex:15-19`

```elixir
@remember_me_options [sign: true, max_age: ..., same_site: "Lax"]
```

Without `secure: true`, the cookie can be sent over plain HTTP (before HTTPS redirect fires). Without `http_only: true`, it's accessible to client-side JavaScript, making it vulnerable to XSS-based token theft.

**Fix:** Add `secure: true, http_only: true` to `@remember_me_options`.

---

## High

### H1: No Rate Limiting on Authentication Endpoints

**Files:** `lib/atlas_web/live/user_live/login.ex`, `lib/atlas_web/controllers/user_session_controller.ex`, `lib/atlas_web/live/user_live/registration.ex`

No rate limiting on any authentication endpoint:
- Password login — unlimited brute-force attempts per IP/account
- Magic link requests — unlimited emails to a target address (email bombing)
- User registration — no CAPTCHA or throttle on account creation

**Fix:** Add rate limiting (e.g., Hammer, PlugAttack) to login, registration, and magic link endpoints.

---

### H2: Moderator Can Promote/Demote Other Moderators (Owner-Only Action)

**File:** `lib/atlas_web/live/community_live/moderation/team_members.ex:53-61`

The `toggle-moderator` handler only checks that the target is not the owner. It does not verify the acting user is the community **owner**. Any moderator can promote members to moderator or demote fellow moderators.

**Fix:** Add `if socket.assigns.is_owner` guard before `maybe_toggle_role`.

---

### H3: Protocol-Relative URL Bypass in `safe_url?`

**File:** `lib/atlas_web/components/block_renderer.ex:192-200`

```elixir
defp safe_url?(url) when is_binary(url) do
  case URI.parse(url) do
    %{scheme: scheme} when scheme in ~w(http https mailto) -> true
    %{scheme: nil} -> true   # <-- allows //evil.com
    _ -> false
  end
end
```

The `%{scheme: nil} -> true` clause allows protocol-relative URLs like `//evil.com/phishing`. These inherit the page's protocol and can point to any host. Users can create content with links to `//evil.com` that pass validation and render as clickable links.

**Fix:** Add a check that `nil`-scheme URLs don't start with `//`:

```elixir
%{scheme: nil} -> not String.starts_with?(url, "//")
```

---

### H4: Avatar URL Has No Scheme Validation

**File:** `lib/atlas/accounts/user.ex:179-183`

```elixir
def avatar_changeset(user, attrs) do
  user
  |> cast(attrs, [:avatar_url])
  |> validate_length(:avatar_url, max: 500)
end
```

Only validates length, not URL scheme. A malicious client can send `pushEvent("logo-uploaded", {url: "javascript:alert(1)"})` via WebSocket. While `<img src="javascript:...">` doesn't execute in modern browsers, `data:` URIs and external tracking pixels can be stored. Community icons have proper scheme validation (`validate_icon_url` checks for http/https), but avatars do not.

**Fix:** Add scheme validation matching `Community.validate_icon_url/1`.

---

### H5: Arbitrary JSON Content Stored Without Server-Side Validation

**Files:** `lib/atlas_web/live/page_live/edit.ex:41-42`, `lib/atlas_web/live/page_live/propose.ex:52-53`, `lib/atlas_web/live/proposal_live/edit.ex:94-95`

The `editor-updated` event accepts `blocks` data directly from the WebSocket with zero server-side validation. No limits on:
- Maximum number of blocks
- Maximum depth of nested content
- Maximum total JSON payload size
- Block type whitelist

A malicious user could submit extremely large payloads (megabytes of deeply nested JSON), causing DoS through memory exhaustion on render.

**Fix:** Validate block structure, enforce max block count and total payload size. At minimum, limit total JSON size (e.g., 1MB).

---

### H6: Context Functions Perform No Authorization Checks

**Files:**
- `lib/atlas/communities/pages_context.ex:23-49` — `create_page`, `update_page`
- `lib/atlas/communities/proposals.ex:10-28, 122-163` — `create_proposal`, `approve_proposal`, `reject_proposal`
- `lib/atlas/communities/community_manager.ex:89-93, 138-148` — `update_community`, `set_member_role`
- `lib/atlas/communities/reports_context.ex:60-78` — `resolve_report`, `remove_reported_content`

All context-layer functions trust the caller has already performed authorization. This means any future code path that calls these functions without going through LiveView authorization guards will have an authorization bypass. This is an architectural risk.

**Fix:** Consider adding authorization checks at the context layer for sensitive operations, or document the pattern clearly and add tests that verify LiveView guards.

---

## Medium

### M1: Database SSL Disabled in Production

**File:** `config/runtime.exs:46`

```elixir
# ssl: true,
```

Database SSL is explicitly commented out. If the database is on a separate server, all traffic (including credentials) is unencrypted.

**Fix:** Enable `ssl: true` for production database connections.

---

### M2: Session Cookie Missing `secure: true` Flag

**File:** `lib/atlas_web/endpoint.ex:7-12`

The main `@session_options` does not specify `secure: true`. While `force_ssl` is in prod, the cookie itself lacks the Secure attribute. During the window before HSTS kicks in (first request), the cookie could be sent over HTTP.

**Fix:** Add `secure: true` to `@session_options` (conditionally for production).

---

### M3: No Content Security Policy (CSP) Header

**Files:** `lib/atlas_web/endpoint.ex`, `lib/atlas_web/router.ex:12`

No CSP header is configured. `put_secure_browser_headers` adds `x-frame-options` etc. but not CSP. Without CSP, the app has reduced XSS defense-in-depth — particularly relevant since the app renders user content via `Phoenix.HTML.raw()` and embeds YouTube iframes.

**Fix:** Add CSP header via `put_secure_browser_headers` with directives for `script-src`, `img-src`, `frame-src`.

---

### M4: Account Deletion Does Not Invalidate Active Sessions

**File:** `lib/atlas_web/live/user_live/settings.ex:196-208`

When a user deletes their account, `delete_user` only deletes the user row. There is no call to `disconnect_sessions/1` to broadcast disconnect events. Other active browser tabs or LiveView sockets remain connected until the next session validation. Compare to proper logout flow which broadcasts disconnect.

**Fix:** Call `Accounts.disconnect_sessions(user)` before `Accounts.delete_user(user)`.

---

### M5: Upload Community Path Parameter Not Sanitized

**File:** `lib/atlas/uploads.ex:115-118`

```elixir
defp generate_key(filename, community) do
  uuid = Ecto.UUID.generate()
  sanitized = sanitize_filename(filename)
  "#{community}/#{uuid}/#{sanitized}"
end
```

The `community` parameter comes directly from the client request body and is interpolated into the S3 key path without sanitization. A malicious user could pass `community: "../../other-path"` to manipulate the S3 key.

**Fix:** Sanitize `community` the same way filenames are sanitized, or validate against known community names.

---

### M6: Proposal Author Can Self-Approve

**File:** `lib/atlas_web/live/proposal_live/show.ex:72-83`, `lib/atlas/authorization.ex:31-40`

`can_review_proposal?` checks if the user is the page owner or a moderator. If a moderator submits a proposal, they can also approve it themselves. No explicit check prevents self-approval.

**Fix:** Add `proposal.user_id != user.id` check in `can_review_proposal?` or in the approve handler.

---

### M7: Fragile `highlight_text` + `raw()` Pipeline

**File:** `lib/atlas_web/components/block_renderer.ex:152-170, 214-219`

The text rendering pipeline: `html_escape` -> `safe_to_string` -> `highlight_text` (inserts `<mark>` tags) -> `Phoenix.HTML.raw()`. The pattern of escaping first, then inserting raw HTML, then marking as safe is currently correct but brittle. Any change to the order of operations could introduce XSS.

**Risk:** Currently safe. Architectural fragility.

---

### M8: Section/Proposal Content Has No Size Limits

**File:** `lib/atlas/communities/section.ex:15-20`, `lib/atlas/communities/proposal.ex:22-28`

The `content` and `proposed_content` fields are typed as `{:array, :map}` with no validation on size, depth, or block count. Combined with `data:image/` URLs being allowed, users could embed multi-megabyte payloads.

**Fix:** Add maximum total content size validation at the changeset level.

---

### M9: `heading.id` Used as HTML `id` Without Validation

**File:** `lib/atlas_web/components/block_renderer.ex:49, 53, 57, 61`

```elixir
<h1 id={@block["id"]} class="...">
```

The `id` comes from unvalidated user-provided BlockNote JSON. HEEx auto-escapes attribute values (preventing XSS), but an attacker could set block IDs that collide with existing DOM element IDs, potentially interfering with application functionality (DOM clobbering).

**Fix:** Prefix block IDs (e.g., `block-#{@block["id"]}`) or validate format.

---

### M10: YouTube Video ID Not Validated for Format

**File:** `lib/atlas_web/components/block_renderer.ex:103, 114-136`

```elixir
src={"https://www.youtube-nocookie.com/embed/#{@video_id}"}
```

The extracted video ID could contain characters like `?autoplay=1&` that modify embed behavior. Phoenix attribute interpolation auto-escapes, limiting the attack surface, but the ID should be validated.

**Fix:** Validate video IDs contain only `[a-zA-Z0-9_-]`.

---

## Low

### L1: Password Complexity Requirements Are Minimal

**File:** `lib/atlas/accounts/user.ex:148-157`

Only enforces length (12-72 chars). All complexity checks are commented out. Passwords like `"aaaaaaaaaaaa"` are accepted.

---

### L2: `String.to_integer` on User Input Without Error Handling

**Files:** `lib/atlas_web/components/comments_section.ex:139, 143`

`String.to_integer/1` raises `ArgumentError` on non-numeric input. A malicious WebSocket client can cause process crashes. Use `Integer.parse/1` with pattern matching instead.

---

### L3: `filter-proposals` Does Not Validate `status` Parameter

**File:** `lib/atlas_web/live/community_live/moderation/proposals.ex:30-31`

The `status` string is passed directly to `list_community_proposals` without validating it's one of `"pending"`, `"approved"`, `"rejected"`. Ecto parameterizes queries (no SQL injection), but defense-in-depth is lacking.

---

### L4: No Content-Disposition Header on S3 Uploads

**File:** `lib/atlas/uploads.ex:30-95`

Presigned URLs don't set `Content-Disposition` on uploaded objects. If allowed types ever expand to include SVG or HTML, files could execute JavaScript when served inline.

---

### L5: Static Signing Salts Hardcoded in Source

**Files:** `lib/atlas_web/endpoint.ex:10`, `config/config.exs:36`

Session and LiveView signing salts are committed to source control. Combined with `secret_key_base`, these are used for cookie signing. Any contributor with repo access knows the salts. Standard Phoenix practice, but worth noting.

---

### L6: `.env` Not in `.gitignore`

No `.env` files exist in the repo, but `.env*` is not in `.gitignore` as a preventive measure.

---

### L7: No Rate Limiting on Proposals, Comments, Reports

**Files:** Various LiveView handlers

No rate limiting on proposal creation, comment posting, or report submission. A malicious user could flood a page with content.

---

## Informational

| Finding | Status |
|---------|--------|
| CSRF protection properly configured (`protect_from_forgery` plug) | Good |
| Bcrypt with timing-attack protection (`no_user_verify`) | Good |
| Token generation uses `:crypto.strong_rand_bytes/1` (32 bytes) | Good |
| Session fixation prevention (`renew_session`, `delete_csrf_token`) | Good |
| `force_ssl` correctly configured in production | Good |
| Authorization module has nil guards on all functions | Good |
| Edit changesets properly restrict fields (prevent mass assignment) | Good |
| SQL queries use parameterized bindings (no SQL injection) | Good |
| ILIKE searches properly escape `\`, `%`, `_` | Good |
| No server-side URL fetching (no SSRF) | Good |
| No `System.cmd` or `:os.cmd` usage (no command injection) | Good |
| Filename sanitization in uploads is adequate | Good |
| S3 presigned URL includes content-type in signature | Good |
| `check_origin` disabled only in development | Good |
| Debug errors disabled in production | Good |

---

## Priority Fix Order

1. **C1** — IDOR on report resolution (small code change, high impact)
2. **H3** — Protocol-relative URL bypass (one-liner)
3. **H4** — Avatar URL scheme validation (small)
4. **H2** — Moderator toggle missing owner check (small)
5. **C3** — Remember-me cookie flags (one-liner)
6. **M2** — Session cookie secure flag (one-liner)
7. **C2** — Session cookie encryption (add encryption_salt)
8. **H5** — Content size validation (medium effort)
9. **M3** — CSP header (medium effort)
10. **H1** — Rate limiting (significant effort, requires new dependency)
