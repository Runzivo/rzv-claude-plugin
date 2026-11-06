# Releasing

1. Run every check in [testing.md](testing.md), including the live test.
2. Raise `version` in `.claude-plugin/plugin.json` and add a section to
   `CHANGELOG.md`. Users only receive a release when the version changes.
3. Merge to `main`, then tag the merge commit `vX.Y.Z` and push the tag.
4. Publish a GitHub release for the tag with the changelog section.
5. Check the install from GitHub:

   ```sh
   claude plugin marketplace add Runzivo/rzv-claude-plugin
   claude plugin install runzivo@runzivo
   claude plugin details runzivo
   ```

   Users who already have it run `claude plugin update runzivo@runzivo`.

## Anthropic's directory

The directory lists the plugin on claude.ai and in Claude Code. A workspace
owner with a paid claude.ai plan and a connected GitHub account submits it:

1. Open https://claude.ai/directory/manage and select **Submit new**.
2. Choose **Plugin bundle**. Repository `Runzivo/rzv-claude-plugin`, plugin
   path empty (the root), branch `main`. Select **Validate**.
3. Check the listing name and description, answer the data handling questions
   from [privacy.md](privacy.md), add the contact email, accept the four
   acknowledgements, and choose the GitHub push webhook for updates.
4. Select **Submit for review**. Later versions are picked up from `main`.

Back to the [README](../README.md).
