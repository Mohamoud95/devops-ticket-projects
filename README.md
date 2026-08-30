# DevOps Ticket Projects

I am using this repository to work through practical DevOps tickets and document how I analyse, implement, test, and improve each solution.

My focus is not only reaching a working result. I want to understand the underlying Linux, automation, security, testing, and operational concepts well enough to explain my decisions clearly.

## Current Progress

| Ticket | Project | Status |
|---|---|---|
| 001 | Jenkins CI/CD pipeline for a Java app | Completed |
| 081 | Safe log-retention automation with Bash | Completed |

## Working Method

For each ticket, I document:

- the operational problem
- clear acceptance criteria
- implementation decisions
- safety and security considerations
- tests and edge cases
- original evidence
- lessons learned

## Repository Structure

```text
tickets/
  001-jenkins-java-pipeline/
    README.md
    Jenkinsfile
    compose.yaml
    pom.xml
    src/
    docs/
      IMPLEMENTATION_LOG.md
  081-log-cleanup/
    README.md
    scripts/
    tests/
    evidence/
```

## Security And Evidence

I use synthetic test data before working with operational files. I do not commit passwords, private keys, tokens, personal data, or unredacted secrets. Evidence is limited to genuine screenshots that demonstrate meaningful results without repeating the same information.
