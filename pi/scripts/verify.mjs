#!/usr/bin/env node

import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const profileRoot = resolve(scriptDir, "..");

let targetHome = homedir();
let requirePackages = false;
for (let index = 2; index < process.argv.length; index += 1) {
	const argument = process.argv[index];
	if (argument === "--home") {
		targetHome = resolve(process.argv[++index]);
	} else if (argument === "--require-packages") {
		requirePackages = true;
	} else {
		throw new Error(`Unknown argument: ${argument}`);
	}
}

function fail(message) {
	throw new Error(message);
}

function readJson(path) {
	return JSON.parse(readFileSync(path, "utf8"));
}

function assertEqual(actual, expected, label) {
	if (JSON.stringify(actual) !== JSON.stringify(expected)) {
		fail(`${label} does not match the versioned profile`);
	}
}

function collectFiles(path, result = []) {
	for (const entry of readdirSync(path)) {
		const child = join(path, entry);
		const stat = statSync(child);
		if (stat.isDirectory()) collectFiles(child, result);
		else result.push(child);
	}
	return result;
}

const forbiddenNames = new Set(["auth.json", "sessions", "npm", "git"]);
for (const path of collectFiles(profileRoot)) {
	for (const segment of path.slice(profileRoot.length + 1).split("/")) {
		if (forbiddenNames.has(segment)) {
			fail(`Runtime or credential path is present in the profile: ${path}`);
		}
	}
}

const sourceSettings = readJson(join(profileRoot, "agent", "settings.json"));
const serializedSourceSettings = JSON.stringify(sourceSettings);
if (/\/home\/|[A-Za-z]:\\\\Users\\\\/.test(serializedSourceSettings)) {
	fail("Versioned settings contain a machine-specific home path");
}
assertEqual(sourceSettings.extensions, [
	"~/.pi/agent/all-tools.ts",
	"~/.pi/agent/extensions/preset.ts",
], "Extension paths");
assertEqual(sourceSettings.packages, [
	"npm:pi-lens@3.8.62",
	"npm:pi-web-access@0.13.0",
], "Package pins");

const sourceWebConfig = readJson(join(profileRoot, "web-search.json"));
for (const key of Object.keys(sourceWebConfig)) {
	if (/(api.?key|token|secret|auth)/i.test(key)) {
		fail(`Secret-bearing field found in versioned web configuration: ${key}`);
	}
}

const agentDir = join(targetHome, ".pi", "agent");
const installedSettings = readJson(join(agentDir, "settings.json"));
for (const key of [
	"theme",
	"defaultProvider",
	"defaultModel",
	"defaultThinkingLevel",
	"extensions",
	"packages",
]) {
	assertEqual(installedSettings[key], sourceSettings[key], `Installed setting "${key}"`);
}

const sourceAllTools = readFileSync(join(profileRoot, "agent", "all-tools.ts"), "utf8");
const installedAllTools = readFileSync(join(agentDir, "all-tools.ts"), "utf8");
if (sourceAllTools !== installedAllTools) fail("Installed all-tools extension differs from the profile");

const presets = readJson(join(agentDir, "presets.json"));
for (const name of ["Rust Analyst", "Brainstormer"]) {
	const source = readFileSync(join(profileRoot, "profiles", `${name}.md`), "utf8");
	if (presets[name]?.instructions !== source) {
		fail(`Installed "${name}" preset differs from its canonical Markdown profile`);
	}
}
assertEqual(Object.keys(presets).sort(), ["Brainstormer", "Rust Analyst"], "Preset names");

const presetExtension = join(agentDir, "extensions", "preset.ts");
if (!existsSync(presetExtension)) fail("Pi's bundled preset extension was not installed");
if (!readFileSync(presetExtension, "utf8").includes("Preset Extension")) {
	fail("Installed preset extension does not look like Pi's bundled extension");
}

const installedWebConfig = readJson(join(targetHome, ".pi", "web-search.json"));
if (installedWebConfig.provider !== "exa" || installedWebConfig.webSearch?.enabled !== true) {
	fail("Installed web configuration does not enable Exa search");
}

if (requirePackages) {
	const expectedPackages = new Map([
		["pi-lens", "3.8.62"],
		["pi-web-access", "0.13.0"],
	]);
	for (const [name, version] of expectedPackages) {
		const manifest = join(agentDir, "npm", "node_modules", name, "package.json");
		if (!existsSync(manifest)) fail(`Required package is not installed: ${name}`);
		const installedVersion = readJson(manifest).version;
		if (installedVersion !== version) {
			fail(`${name} version ${installedVersion} is installed; expected ${version}`);
		}
	}

	const expectedBrowseVersion = readJson(join(profileRoot, "external-tools.json")).browse;
	const browseRoot = join(
		targetHome,
		".local",
		"share",
		"muradkant-pi-profile",
		"browse",
		"node_modules",
		"browse",
	);
	const browseManifest = join(browseRoot, "package.json");
	if (!existsSync(browseManifest)) fail("Browse CLI is not installed");
	if (readJson(browseManifest).version !== expectedBrowseVersion) {
		fail(`Browse CLI version does not match ${expectedBrowseVersion}`);
	}

	const bundledBrowseSkill = readFileSync(join(browseRoot, "skills", "browse", "SKILL.md"), "utf8");
	const sharedBrowseSkill = readFileSync(
		join(targetHome, ".agents", "skills", "browse", "SKILL.md"),
		"utf8",
	);
	if (bundledBrowseSkill !== sharedBrowseSkill) {
		fail("Installed Browse skill differs from the pinned CLI's bundled official skill");
	}

	const piBrowseSkill = join(agentDir, "skills", "browse", "SKILL.md");
	if (!existsSync(piBrowseSkill) || readFileSync(piBrowseSkill, "utf8") !== bundledBrowseSkill) {
		fail("Pi does not resolve the installed official Browse skill");
	}

	const browseExecutable = join(targetHome, ".local", "bin", "browse");
	if (!existsSync(browseExecutable)) fail("Browse CLI executable is not linked into ~/.local/bin");
}

console.log(`Pi profile verified for ${targetHome}`);
