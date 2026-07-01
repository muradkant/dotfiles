import { writeFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function profileProbe(pi: ExtensionAPI) {
	pi.on("session_start", async () => {
		const output = process.env.PI_PROFILE_PROBE;
		if (!output) return;
		writeFileSync(
			output,
			`${JSON.stringify({
				activeTools: [...pi.getActiveTools()].sort(),
				allTools: pi.getAllTools().map((tool) => tool.name).sort(),
			}, null, 2)}\n`,
		);
	});
}
