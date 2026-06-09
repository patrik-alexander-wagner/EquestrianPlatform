---
name: Express mounted-router relative req.path
description: req.path is relative to the mount point inside app.use("/api", ...) — matters for path-based allow/deny guards
---

Inside an Express middleware mounted with `app.use("/api", ...)`, `req.path` is **relative to the mount point** (e.g. `/login`, not `/api/login`).

**Why:** A global read-only guard (blocks non-GET for `VIEWER` role) must allow logout. Matching `"/api/logout"` would never fire; the correct match is `"/logout"`.

**How to apply:** When writing path allow/deny lists in a middleware registered under a mount prefix, compare against the prefix-stripped path. Use `req.originalUrl` if you need the full path.
