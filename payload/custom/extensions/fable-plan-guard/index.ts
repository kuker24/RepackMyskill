import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent"

type PlanEntry = {
  type?: string
  customType?: string
  data?: {
    phase?: string
  }
}

function getPlanPhase(ctx: ExtensionContext): string {
  const entries = ctx.sessionManager.getEntries() as PlanEntry[]

  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index]

    if (
      entry.type === "custom" &&
      entry.customType === "pi-plan-extension"
    ) {
      return entry.data?.phase ?? "idle"
    }
  }

  return "idle"
}

export default function fablePlanGuard(pi: ExtensionAPI): void {
  pi.on("tool_call", async (event, ctx) => {
    if (getPlanPhase(ctx) !== "planning") {
      return
    }

    const toolName = String(event.toolName).toLowerCase()

    if (toolName === "agent" || toolName.includes("subagent")) {
      return {
        block: true,
        reason:
          "Plan Mode aktif. Delegasi ke subagent diblokir karena subagent " +
          "dapat mengubah project. Selesaikan perencanaan atau keluar dengan /plan.",
      }
    }
  })

  pi.on("before_agent_start", async (event, ctx) => {
    if (getPlanPhase(ctx) !== "planning") {
      return
    }

    return {
      systemPrompt:
        event.systemPrompt +
        `

[FABLE PLAN GUARD ACTIVE]

Plan Mode sedang aktif.

Dilarang:
- memanggil Agent atau subagent
- mendelegasikan pekerjaan kepada Terra
- mengubah source code
- menjalankan command mutasi
- melakukan commit, push, install, atau deploy

Gunakan fase ini hanya untuk inspeksi read-only, pembahasan keputusan, dan
pembuatan atau pembaruan file rencana melalui create_plan atau update_plan.`,
    }
  })
}
