import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

type AgentInput = {
  subagent_type?: unknown
  isolation?: unknown
}

const FABLE_AGENT_TYPES = new Set([
  "fable-luna",
  "fable-sol",
  "fable-terra",
])

export default function fableAgentCompat(pi: ExtensionAPI): void {
  pi.on("tool_call", (event) => {
    if (String(event.toolName).toLowerCase() !== "agent") {
      return
    }

    const input = event.input as AgentInput
    if (typeof input.subagent_type === "string" && FABLE_AGENT_TYPES.has(input.subagent_type)) {
      delete input.isolation
    }
  })
}
