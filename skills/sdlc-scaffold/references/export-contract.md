# Export contract (proposal §12)

`export-proposal.sh` renders an **accepted** workflow contract into
reviewable proposal files. It never applies, merges, installs, or publishes.

## Gates, in order

1. **Roots.** `--input` (contract file or modular dir), `--client` (repo the
   proposal describes), `--output` (destination). The output root must exist
   and must not overlap the input or client roots — checked after symlink
   resolution, both directions.
2. **Acceptance.** `--acceptance` names a sibling `contract-acceptance/0.1.0`
   record (`_config/contract-acceptance-schema.md`): `decision: accept` and a
   `contract_digest` matching the contract's current normalized content are
   required. Editing the contract after review invalidates acceptance. The
   exporter reads the record; nothing here creates approval.
3. **Contract validity.** `validate-workflow-contract.sh` must pass.
4. **Render to staging.** Contract blocks are emitted verbatim plus minimal
   derived prose; `context_entry` items are classified and relocated:
   runtime artifacts and named resources stay verbatim; client-repository
   paths stay verbatim and resolve at the client root; bundled files are
   copied to the declaring-file-relative path inside the package. Entries
   resolving nowhere are unrelocatable — export refuses.
5. **Staged validation.** The rendered tree must pass contract validation
   and `check-loading-rules.sh` (with the client root for the
   client-repository class). For `--form both`, both subtrees must also
   normalize identically.
6. **Preflight + publish.** Every staged file is classified against the
   destination first: `SAME` (identical, untouched), `CREATE` (new),
   `REFUSE` (existing, differs). Every destination path is verified through
   its ancestors: symlinks must resolve inside the output root (dangling
   links fail closed), existing ancestors must be directories, and a
   directory at the file's own path is a conflict. Containment is rechecked
   per file immediately before writing. Any refusal writes nothing —
   including files that would have been new — and reports the cause. On
   success only `CREATE`s are written.

## Failure handling

- All refusals happen before the first write; the destination is unchanged.
- Publish is **not crash-atomic**: a mid-publish write failure can leave a
  partial package. The report names written and remaining files; rerunning
  converges because `SAME`/`CREATE` are idempotent.
- Staging lives in `mktemp -d` and is removed on exit.

## Determinism

Identical inputs and renderer version produce byte-identical output — no
timestamps or absolute paths are emitted. `EXPORT-REPORT.md` in the package
records the renderer version, contract digest, and the relocation class of
every `context_entry` item.

## Boundaries

Observation snapshots are not contracts and are refused. Observation →
contract promotion, applying a proposal to the client repository, install,
merge, and publication are all outside this script's authority.
