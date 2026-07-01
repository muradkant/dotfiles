#!/usr/bin/env node

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const profileRoot = resolve(scriptDir, "..");
const outputPath = process.argv[2];

const profileFiles = [
	["Rust Analyst", "Rust Analyst.md"],
	["Brainstormer", "Brainstormer.md"],
];

const presets = Object.fromEntries(
	profileFiles.map(([name, filename]) => [
		name,
		{ instructions: readFileSync(join(profileRoot, "profiles", filename), "utf8") },
	]),
);

const rendered = `${JSON.stringify(presets, null, 2)}\n`;
if (outputPath) {
	writeFileSync(outputPath, rendered, { mode: 0o644 });
} else {
	process.stdout.write(rendered);
}
