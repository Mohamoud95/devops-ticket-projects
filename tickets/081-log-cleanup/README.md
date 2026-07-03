# Ticket 081 - Safe Log-Retention Automation

## Status

Completed.

## Scenario

A Linux host is accumulating old application logs. I need to build a Bash script that identifies and removes log files older than a defined retention period without affecting recent logs, directories, symbolic links, or unrelated paths.

## Objective

Create a safe and testable log-cleanup utility, initially using synthetic files in an isolated directory.

## Acceptance Criteria

- Select only regular files older than the configured retention period.
- Preserve files that are still within retention.
- Do not delete directories or symbolic links.
- Validate the target directory before performing work.
- Provide a dry-run mode that makes no changes.
- Record meaningful actions and errors.
- Return useful exit codes.
- Demonstrate repeatable tests with files of known ages.

## Safety Approach

I developed this against synthetic log files under my home directory rather than using `/var/log`. I tested the selection logic first, confirmed preview mode did not delete anything, and only then tested delete mode with an explicit `--delete` flag.

## Implementation

The script is available at:

```text
scripts/cleanup-logs.sh
```

It uses a 30-day retention policy and supports two modes:

```bash
bash scripts/cleanup-logs.sh <log-directory>
bash scripts/cleanup-logs.sh --delete <log-directory>
```

Preview mode is the default. Delete mode must be requested explicitly with `--delete`.

Key implementation choices:

- I used `find` with `-maxdepth 1`, `-type f`, and `-mtime +30` so only regular files older than the retention period are selected.
- I used `-print0` with `mapfile -d ''` so filenames with spaces are handled safely.
- I validate the target directory before doing any work.
- I reject symbolic-link directories and the root directory as safety checks.
- I log actions with timestamps so the script output can be reviewed later.
- I return different exit codes for usage errors, validation failures, and deletion failures.

## Testing

Tested cases:

- current file retained
- 10-day-old file retained
- 31-day-old file selected and deleted only in delete mode
- 45-day-old file selected and deleted only in delete mode
- missing target rejected
- preview mode makes no changes
- delete mode removes only files older than the retention period

## Evidence

Selected evidence:

![Delete mode successfully removed only old logs](evidence/01-delete-mode-success.png)

## Lessons Learned

This ticket helped me understand how to build safer Bash automation rather than only writing a command that works once.

I learned why destructive scripts should have a preview mode, why arguments need validation, and how `find -mtime` uses file metadata instead of filenames.
