// ~/.npm-init.js — scaffolds a hardened package.json on every `npm init`.
// Wired up via npm's init-module config (default path, already active).
// Added 2026-08-09 as part of supply-chain hardening.

const path = require('path');

module.exports = {
  name: path.basename(process.cwd()),
  version: '1.0.0',
  private: true,
  type: 'module',

  // Paired with engine-strict=true in ~/.npmrc, this makes npm REFUSE to
  // install under an npm that predates min-release-age support. Without it,
  // npm 11 or older silently ignores the cooldown.
  engines: {
    node: '>=26',
    npm: '>=12'
  },

  scripts: {
    // Fails the build if any dependency is younger than the cooldown or
    // carries a moderate+ advisory.
    audit: 'npm audit --audit-level=moderate'
  },

  // Force a single resolved version for transitive deps. Use this to pin a
  // package that a nested dependency would otherwise float:
  //   "overrides": { "some-pkg": "1.2.3" }
  overrides: {}
};
