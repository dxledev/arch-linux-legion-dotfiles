#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const providersPath = path.resolve(__dirname, "../../services/AIUsageProviders.js");
const providersSource = fs.readFileSync(providersPath, "utf8").replace(/^\.pragma library\s*/, "");
const providers = {};
vm.runInNewContext(providersSource, providers, {filename: providersPath});

const valid = providers.parseDiscoveryResult(0, JSON.stringify({
    ok: true,
    providerIds: ["openai@work", "openai@work", "custom:internal", "", 42, "anthropic@personal"]
}), false);
assert.equal(valid.ok, true);
assert.deepEqual(JSON.parse(JSON.stringify(valid.providerIds)), ["openai@work", "custom:internal", "anthropic@personal"]);

assert.equal(providers.parseDiscoveryResult(1, "", false).ok, false, "failed discovery is rejected");
assert.equal(providers.parseDiscoveryResult(0, "{bad", false).ok, false, "malformed discovery is rejected");
assert.equal(providers.parseDiscoveryResult(124, "", true).ok, false, "timed out discovery is rejected");

const entries = [
    {id: "openai", displayName: "OpenAI", failed: false},
    {id: "openai@work", displayName: "OpenAI · work", failed: false},
    {id: "openai@personal", displayName: "OpenAI · personal", failed: true},
    {id: "custom:internal", displayName: "Internal · staging", failed: true},
    {id: "anthropic@personal", displayName: "Anthropic · personal", failed: false}
];
assert.deepEqual(
    JSON.parse(JSON.stringify(providers.availableEntries(entries, ["openai@personal", "custom:internal"]))),
    [entries[2], entries[3]],
    "only configured account IDs survive, including configured error rows"
);
assert.deepEqual(JSON.parse(JSON.stringify(providers.availableEntries(entries, null))), [], "missing metadata exposes no providers");

console.log("PASS: AI Usage discovery result parsing and exact configured account filtering");
