# Port MCP Local Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure the project-local Port MCP server and Port usage skill.

**Architecture:** OpenCode loads `.opencode/opencode.json` from the project and
connects to `port-us` as a native remote MCP server with OpenCode-managed OAuth.
The skill loader scans
`.opencode/skills/port/SKILL.md` for Port-specific operating guidance.

**Tech Stack:** JSON, Markdown, OpenCode remote MCP and OAuth.

---

### Task 1: Add project-local OpenCode configuration

**Files:**
- Create: `.opencode/opencode.json`

- [ ] **Step 1: Validate JSON syntax**

Run:

```bash
node -e 'JSON.parse(require("fs").readFileSync(".opencode/opencode.json", "utf8"))'
```

Expected: command exits successfully without output.

- [ ] **Step 2: Verify MCP command configuration**

Run:

```bash
node -e 'const c=require("./.opencode/opencode.json"); const s=c.mcp["port-us"]; if(s.type!=="local" || s.command.join(" ")!=="npx -y mcp-remote https://mcp.us.port.io/v1 --header x-read-only-mode: 0") process.exit(1)'
```

Expected: command exits successfully without output.

### Task 2: Add Port local skill

**Files:**
- Create: `.opencode/skills/port/SKILL.md`

- [ ] **Step 1: Check skill frontmatter and required guidance**

Run:

```bash
node -e 'const fs=require("fs"); const s=fs.readFileSync(".opencode/skills/port/SKILL.md", "utf8"); for(const x of ["name: port", "description:", "port-us", "current state", "invent Port resource identifiers"]) if(!s.includes(x)) process.exit(1)'
```

Expected: command exits successfully without output.

### Task 3: Authenticate and validate the MCP connection

**Files:**
- Verify: `.opencode/opencode.json`

- [ ] **Step 1: Authenticate with Port**

Run:

```bash
opencode mcp auth port-us
```

Expected: a browser opens to Port OAuth; sign in and approve access.

- [ ] **Step 2: Verify the authenticated server**

Run:

```bash
opencode mcp list
```

Expected: `port-us` is listed as connected or ready rather than failed.
