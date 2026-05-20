#!/usr/bin/env node
/**
 * AIOS MCP Server
 *
 * Exposes Paios rules, presets, and project state as MCP resources and tools.
 * Can be used by Codex, Claude Code, and other MCP-compatible clients.
 *
 * Usage:
 *   node server.js
 *
 * Configure in Codex plugin.json:
 *   "mcpServers": {
 *     "aios": {
 *       "command": "node",
 *       "args": ["path/to/Paios/mcp/server.js"]
 *     }
 *   }
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { readFileSync, readdirSync, statSync, existsSync } from "fs";
import { join, resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "..");

// ─── Resource handlers ───

const server = new Server(
  { name: "aios-mcp", version: "1.0.0" },
  { capabilities: { resources: {}, tools: {} } }
);

// ─── List available resources ───
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const rulesDir = join(ROOT, "rules");
  const presetsDir = join(ROOT, "templates", "presets");
  const rules = readdirSync(rulesDir).filter(f => f.endsWith(".yaml"));
  const presets = readdirSync(presetsDir).filter(f => f.endsWith(".yaml"));
  const skillDirs = readdirSync(join(ROOT, "skills")).filter(d => d.startsWith("pai-"));

  return {
    resources: [
      // Rules
      ...rules.map(name => ({
        uri: `aios://rules/${name.replace(".yaml", "")}`,
        name: `Rule: ${name}`,
        description: `AIOS rule set: ${name}`,
        mimeType: "text/yaml",
      })),
      // Presets
      ...presets.map(name => ({
        uri: `aios://presets/${name.replace(".yaml", "")}`,
        name: `Preset: ${name}`,
        description: `AIOS tech stack preset: ${name}`,
        mimeType: "text/yaml",
      })),
      // Skills
      ...skillDirs.map(name => ({
        uri: `aios://skills/${name}`,
        name: `Skill: ${name}`,
        description: `AIOS skill definition: ${name}`,
        mimeType: "text/markdown",
      })),
      // Meta
      {
        uri: "aios://version",
        name: "AIOS Version",
        description: "Current AIOS skill pack version",
        mimeType: "text/plain",
      },
      {
        uri: "aios://changelog",
        name: "AIOS Changelog",
        description: "AIOS version history",
        mimeType: "text/markdown",
      },
    ],
  };
});

// ─── Read a specific resource ───
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;

  // aios://rules/{name}
  let match = uri.match(/^aios:\/\/rules\/(.+)$/);
  if (match) {
    const filePath = join(ROOT, "rules", `${match[1]}.yaml`);
    if (!existsSync(filePath)) throw new Error(`Rule not found: ${match[1]}`);
    return { contents: [{ uri, mimeType: "text/yaml", text: readFileSync(filePath, "utf-8") }] };
  }

  // aios://presets/{name}
  match = uri.match(/^aios:\/\/presets\/(.+)$/);
  if (match) {
    const filePath = join(ROOT, "templates", "presets", `${match[1]}.yaml`);
    if (!existsSync(filePath)) throw new Error(`Preset not found: ${match[1]}`);
    return { contents: [{ uri, mimeType: "text/yaml", text: readFileSync(filePath, "utf-8") }] };
  }

  // aios://skills/{name}
  match = uri.match(/^aios:\/\/skills\/(.+)$/);
  if (match) {
    const filePath = join(ROOT, "skills", match[1], "SKILL.md");
    if (!existsSync(filePath)) throw new Error(`Skill not found: ${match[1]}`);
    return { contents: [{ uri, mimeType: "text/markdown", text: readFileSync(filePath, "utf-8") }] };
  }

  // aios://version
  if (uri === "aios://version") {
    const versionFile = join(ROOT, ".version");
    const version = existsSync(versionFile) ? readFileSync(versionFile, "utf-8").trim() : "unknown";
    return { contents: [{ uri, mimeType: "text/plain", text: version }] };
  }

  // aios://changelog
  if (uri === "aios://changelog") {
    const changelogFile = join(ROOT, "CHANGELOG.md");
    const changelog = existsSync(changelogFile) ? readFileSync(changelogFile, "utf-8") : "# Changelog\n";
    return { contents: [{ uri, mimeType: "text/markdown", text: changelog }] };
  }

  throw new Error(`Unknown resource: ${uri}`);
});

// ─── List available tools ───
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "validate",
      description: "Run AIOS integrity validation (rules, skills, platforms, version)",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "list_presets",
      description: "List available tech stack presets with descriptions",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "list_skills",
      description: "List all AIOS skills with descriptions",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "check_project_state",
      description: "Read ai/state/current.md from the specified project directory to check AIOS project state",
      inputSchema: {
        type: "object",
        properties: {
          project_dir: { type: "string", description: "Absolute path to the project root" },
        },
        required: ["project_dir"],
      },
    },
  ],
}));

// ─── Handle tool calls ───
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case "validate": {
      // Simplified validation - check rules and skills exist
      const rulesCount = readdirSync(join(ROOT, "rules")).filter(f => f.endsWith(".yaml")).length;
      const skillCount = readdirSync(join(ROOT, "skills")).filter(d => d.startsWith("pai-")).length;
      const platformCount = readdirSync(join(ROOT, "platforms")).filter(d => !d.startsWith(".")).length;
      return {
        content: [
          { type: "text", text: `Rules: ${rulesCount}, Skills: ${skillCount}, Platforms: ${platformCount}` },
        ],
      };
    }

    case "list_presets": {
      const presets = readdirSync(join(ROOT, "templates", "presets"))
        .filter(f => f.endsWith(".yaml"))
        .map(f => f.replace(".yaml", ""));
      return {
        content: [{ type: "text", text: presets.join("\n") }],
      };
    }

    case "list_skills": {
      const skills = readdirSync(join(ROOT, "skills"))
        .filter(d => d.startsWith("pai-"))
        .map(name => {
          const skillFile = join(ROOT, "skills", name, "SKILL.md");
          if (!existsSync(skillFile)) return `- ${name}: (no description)`;
          const content = readFileSync(skillFile, "utf-8");
          const descMatch = content.match(/^description:\s*(.+)$/m);
          const desc = descMatch ? descMatch[1].trim() : "(no description)";
          return `- ${name}: ${desc}`;
        });
      return {
        content: [{ type: "text", text: skills.join("\n") }],
      };
    }

    case "check_project_state": {
      const projectDir = args?.project_dir;
      if (!projectDir) throw new Error("project_dir is required");
      const stateFile = join(projectDir, "ai", "state", "current.md");
      const configFile = join(projectDir, "ai", "config.yaml");
      let state = "";
      if (existsSync(stateFile)) {
        state = readFileSync(stateFile, "utf-8");
      }
      let config = "";
      if (existsSync(configFile)) {
        config = readFileSync(configFile, "utf-8");
      }
      return {
        content: [
          { type: "text", text: state ? `## State\n${state}` : "No AIOS state found (not initialized)" },
          { type: "text", text: config ? `## Config\n${config}` : "" },
        ],
      };
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

// ─── Start server ───
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("AIOS MCP server started");
