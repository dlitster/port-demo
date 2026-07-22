# Port MCP Local Configuration Design

## Goal

Provide this project with a local OpenCode configuration for the Port US MCP
server and a project-local skill that guides safe Port operations.

## Configuration

`.opencode/opencode.json` declares the OpenCode schema, registers the local
`.opencode/skills` path, and enables the `port-us` MCP server as a native remote
connection. OpenCode handles OAuth and passes the requested Port header.

## Skill

`.opencode/skills/port/SKILL.md` triggers for Port catalog, blueprint, entity,
scorecard, and action work. It instructs agents to inspect current state first,
avoid invented identifiers, confirm mutation scope, and report outcomes.

## Validation

Validate JSON syntax, confirm the skill layout and frontmatter, and use
OpenCode's MCP commands to authenticate and verify the remote server.
