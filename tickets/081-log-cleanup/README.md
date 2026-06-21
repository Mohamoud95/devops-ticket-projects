# Ticket 081 - Safe Log-Retention Automation

## Status

In progress.

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

I am developing against synthetic log files under my home directory rather than using `/var/log`. Destructive behavior will only be introduced after the selection logic and dry-run output have been verified.

## Implementation

The implementation will be added after I have designed and tested it incrementally.

## Testing

Planned cases:

- current file retained
- 10-day-old file retained
- 31-day-old file selected
- 45-day-old file selected
- directory ignored
- symbolic link ignored
- missing target rejected
- dry run makes no changes
- repeated execution remains safe

## Evidence

Genuine screenshots will be added only when they show a meaningful implementation or verification milestone. Secrets and unrelated terminal history will be excluded.

## Lessons Learned

This section will be completed as I work through the ticket.

