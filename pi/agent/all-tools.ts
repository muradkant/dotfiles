import {
	createFindToolDefinition,
	createGrepToolDefinition,
	createLsToolDefinition,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

/**
 * Make every configured tool active by default.
 *
 * Pi only configures read/bash/edit/write as built-ins by default. Register
 * its other official built-in definitions when no explicit CLI tool policy
 * was supplied, then activate the complete registered tool set.
 */
export default function allToolsExtension(pi: ExtensionAPI) {
	for (const definition of [
		createGrepToolDefinition(process.cwd()),
		createFindToolDefinition(process.cwd()),
		createLsToolDefinition(process.cwd()),
	]) {
		try {
			pi.registerTool(definition);
		} catch {
			// Keep an existing definition when another extension registered it.
		}
	}

	pi.on("session_start", async (_event, _ctx) => {
		const builtins = new Set(["read", "bash", "edit", "write", "grep", "find", "ls"]);
		const hasActiveBuiltin = pi.getActiveTools().some((name) => builtins.has(name));

		// An empty built-in selection means the caller deliberately used
		// --no-tools, --no-builtin-tools, or a custom-only --tools allowlist.
		if (!hasActiveBuiltin) return;

		pi.setActiveTools(pi.getAllTools().map((tool) => tool.name));
	});
}
