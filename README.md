# SCS Unit IV Lab — Ready Project

This project follows the uploaded **SCS Unit4 Lab Handout**. It includes:
- `SavingsVault.sol`: intentionally vulnerable contract for audit practice.
- `SavingsVaultFixed.sol`: hardened version from Part G.
- Solidity tests (`.t.sol`) and TypeScript integration tests (`.ts`).
- Hardhat 3 configuration and scripts.

## Requirements
- Node.js 22.13.0 or newer
- npm
- Git
- For Solidity tests: Foundry-compatible `forge-std` (see below)
- For Slither: Python 3.10+ and Slither 0.11.6+; the handout says to run Slither in WSL on Windows.

## Install
Open the terminal in this folder and run:

```bash
npm install
npm install --save-dev "github:foundry-rs/forge-std#v1.9.7"
```

## Run
```bash
npx hardhat build
npx hardhat test solidity
npx hardhat test nodejs
npx hardhat test
```

If Hardhat says `forge-std/Test.sol` cannot be found, repeat the forge-std install command and run `npx hardhat build` again.

## Slither (optional; run in WSL on Windows)
```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade "slither-analyzer>=0.11.6"
slither --version
npx hardhat build
slither . --filter-paths "node_modules|test"
slither . --filter-paths "node_modules|test" --print human-summary
slither . --filter-paths "node_modules|test" --checklist > slither-report.md
```

## Upload to GitHub
1. Create a repository on GitHub.
2. Extract this ZIP.
3. Open terminal in the extracted `SCS_Unit4_Lab_Ready_Project` folder.
4. Run:
```bash
git init
git add .
git commit -m "Add SCS Unit IV lab project"
git branch -M main
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```
Replace `YOUR_GITHUB_REPOSITORY_URL` with the URL of your own GitHub repository.

## Important notes
- `SavingsVault.sol` is deliberately vulnerable because Part F asks you to audit it. Do not use it with real funds.
- This ZIP is prepared from the lab handout, but dependency versions and local Windows/Node setup can affect the first run. If a command fails, share a screenshot of the terminal error and we can fix it step by step.
- The original handout asks you to add more checklist observations and Slither triage notes; those are learning/report tasks rather than executable code.
