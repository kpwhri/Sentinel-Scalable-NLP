# Jenner compatibility tests

This directory was added by a pull request from the
[Jenner](https://jenneranalytics.com) project. Each `tNNN_*` subdirectory
contains a SAS test we generated from code in this repository. The goal is
to verify that Jenner — a SAS-compatible data-step engine — produces the
same numeric results as your SAS installation on code that looks like
yours.

## What's in here

```
jenner-check/
├── README.md                    # this file
├── run_jenner_check.sas         # master runner
├── jenner_check_report.csv      # written by the runner
├── t001_…/
│   ├── script.sas               # the SAS script under test
│   ├── validate.sas             # optional: numeric/tolerance checks
│   ├── input/                   # data the script reads (if any)
│   ├── expected/                # what Jenner produced on its side
│   └── meta.json                # source file + Jenner version that ran it
└── t002_…/
    └── …
```

## How to run it

From the root of this repository:

```bash
sas -sysin jenner-check/run_jenner_check.sas -set JC_ROOT "$(pwd)"
```

or, from inside `jenner-check/`:

```bash
sas -sysin run_jenner_check.sas
```

The runner will:

1. Find every `tNNN_*` bundle in this directory.
2. Run its `script.sas` with the log and listing captured to
   `<bundle>/actual.log` and `<bundle>/actual.lst`.
3. If the bundle has a `validate.sas`, run that too. A validator produces
   `work.jc_validation` with `status` and `message` columns.
4. Aggregate every test's outcome into `jenner_check_report.csv`.

## How to report results

Please attach `jenner-check/jenner_check_report.csv` as a comment on
the pull request that introduced this directory. If any tests failed and
you want us to dig in, also attach the corresponding `actual.log` and
`actual.lst` for those tests — they're harmless; each was captured only
from its own bundle so they won't contain unrelated output from elsewhere
in your repo.

That's the whole ask. You don't need to merge anything else. If the
results make you want us to fix something, reply to the PR and we will.

## Optional: Jenner Compatible badge

If you'd like to display Jenner compatibility on your README, paste the
markdown below. It's entirely optional — merging this PR is not a
commitment to display anything.

```markdown
[![Jenner Compatible](https://jenneranalytics.com/badges/jenner-compatible.svg)](https://jenneranalytics.com)
```

## Don't want future PRs from us?

Reply to this PR with `no-more-prs` (case-insensitive) anywhere in a
comment, or open an issue titled `jenner-check: opt out`. We'll record
your repo as "do-not-contact" and stop automated PRs.

## About this project

Jenner is an open-source SAS-compatible engine with permissive licensing.
Full context is at [jenneranalytics.com](https://jenneranalytics.com). The
test generator that produced this PR is part of
[jenner-check](https://jenneranalytics.com/jenner-check).
