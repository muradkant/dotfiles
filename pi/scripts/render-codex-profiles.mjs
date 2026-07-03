#!/usr/bin/env node

import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptPath = fileURLToPath(import.meta.url);
const profileRoot = resolve(dirname(scriptPath), "..");

export const codexProfiles = [
	{ slug: "rust-analyst", source: "Rust Analyst.md" },
	{ slug: "brainstormer", source: "Brainstormer.md" },
];

export function renderCodexProfile(markdown) {
	return [
		"# Generated from the canonical dotfiles profile. Do not edit directly.",
		`developer_instructions = ${JSON.stringify(markdown)}`,
		"",
	].join("\n");
}

export function expectedCodexProfile(profile) {
	const markdown = readFileSync(join(profileRoot, "profiles", profile.source), "utf8");
	return renderCodexProfile(markdown);
}

if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
	const outputDirectory = process.argv[2];
	if (!outputDirectory) {
		throw new Error("Usage: render-codex-profiles.mjs OUTPUT_DIRECTORY");
	}

	mkdirSync(outputDirectory, { recursive: true });
	for (const profile of codexProfiles) {
		writeFileSync(
			join(outputDirectory, `${profile.slug}.config.toml`),
			expectedCodexProfile(profile),
		);
	}
}
