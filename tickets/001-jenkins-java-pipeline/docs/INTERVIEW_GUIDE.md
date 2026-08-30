# Ticket 001 Interview Guide

## 30-second summary

I built a Jenkins CI/CD pipeline for a Java 17 application in a GitHub monorepo. Jenkins checks the repository for commits, then compiles with Maven, runs JUnit tests, packages and fingerprints an executable JAR, deploys it to persistent storage, and executes a smoke test. I containerized Jenkins with Maven installed, persisted Jenkins state with a named volume, and documented the full troubleshooting path. A commit adding null-input coverage automatically triggered a successful pipeline with three passing tests.

## STAR answer

### Situation

A Java application needed a repeatable delivery process that ran automatically after source changes. The project lived inside a GitHub monorepo, and the local Docker engine used user-namespace remapping.

### Task

Create an auditable Jenkins pipeline that compiles, tests, packages, and deploys the application while preserving secure defaults and clear operational evidence.

### Action

- Defined the build with Maven and JUnit 5.
- Stored pipeline logic in a version-controlled declarative Jenkinsfile.
- Built a custom Jenkins LTS Java 17 image with Maven and returned execution to the non-root Jenkins user.
- Configured Jenkins to read the monorepo Jenkinsfile and run Maven within the ticket subdirectory.
- Published JUnit reports, archived and fingerprinted the JAR, and added a deployment smoke test.
- Diagnosed Docker socket permissions using group and socket ownership evidence.
- Diagnosed deployment failure using build logs, numeric UID inspection, Docker security options, and the container UID map.
- Kept user namespaces enabled, replaced the incompatible bind mount with Docker-managed persistent storage, corrected scoped residual ownership, and verified non-root write access before rerunning.

### Result

Build 4 was started automatically by an SCM change, passed all three tests, archived the executable JAR, deployed it, printed `Hello, Jenkins!`, and finished successfully in 23 seconds. Jenkins retained the exact Git revision, test report, artifact, fingerprint, and build history.

## Architecture explanation

```text
GitHub main branch
        |
        | SCM polling detects new revision
        v
Jenkins Pipeline job
        |
        +--> Checkout monorepo
        +--> Compile with Maven
        +--> Run JUnit tests and publish XML reports
        +--> Package executable versioned JAR
        +--> Archive and fingerprint artifact
        +--> Copy JAR to persistent Jenkins volume
        `--> Run java -jar smoke test
```

## Key design decisions

### Why Jenkinsfile in Git?

Pipeline-as-code provides reviewable history, rollback, reproducibility, and less hidden UI configuration.

### Why Maven?

Maven supplies a conventional directory structure, dependency resolution, lifecycle phases, test execution, and deterministic configuration through `pom.xml`.

### Why separate Compile, Test, Package, and Deploy stages?

Distinct stages expose failure location, prevent deployment after failed tests, and make timing and ownership clear to operators.

### Why package with `-DskipTests` after a Test stage?

Tests already ran as an explicit quality gate. Skipping the duplicate run during Package reduces repeated work while keeping failures attributable to the Test stage.

### Why polling instead of a webhook?

The lab Jenkins server runs only on localhost and is not safely reachable from GitHub. Polling demonstrates automatic builds without exposing Jenkins publicly. A production design would normally use an authenticated HTTPS webhook.

### Why a named volume for deployment?

Docker user namespaces caused host bind-mount ownership to appear unmapped inside the container. A Docker-managed volume preserves the artifact across container replacement while keeping user-namespace isolation enabled.

## Common interview questions

### What causes later stages to stop after a failure?

Shell commands return exit codes. Maven returns nonzero on compilation or test failure, so Jenkins marks the stage failed and does not execute subsequent stages.

### How are test results exposed in Jenkins?

Maven Surefire writes JUnit XML files under `target/surefire-reports`. The Jenkins `junit` step parses them and creates trendable test reports.

### What is artifact fingerprinting?

Jenkins hashes an archived artifact and records its relationship to a build. This improves traceability across jobs and deployments.

### What is the difference between an image and a container?

An image is an immutable build template. A container is a running instance with a writable layer and attached runtime resources such as networks and volumes.

### Why did UID 1000 become 65534 in the container?

Docker user-namespace remapping maps container IDs into a subordinate host-ID range. A host ID outside that mapping appears as the overflow identity `65534`, commonly named `nobody`.

### Why not fix the failure with `chmod 777`?

It would grant write access to every user and process, weakening security without addressing the ownership model. The chosen fix retained namespace isolation and used Docker-managed storage.

### How would this change for production?

- Pin the Jenkins base image by version or digest.
- Manage Jenkins configuration and plugins as code.
- Use external build agents rather than running builds on the controller.
- Put Jenkins behind HTTPS and restrict network exposure.
- Use webhooks with signature validation.
- Publish artifacts to Nexus, Artifactory, or a container registry.
- Add SAST, dependency scanning, secret scanning, approvals, and deployment rollback.
- Store secrets only in an approved credential manager.

## Honest limitations

- The deployment target is persistent local Jenkins storage, not a remote production environment.
- SCM polling can add latency and consumes periodic repository checks.
- The lab builds on the Jenkins controller; production should use isolated agents.
- The moving Jenkins LTS image tag is not immutable.
- No rollback or environment promotion strategy is implemented yet.

Stating these limitations demonstrates engineering judgment and creates a credible roadmap rather than overstating the project.
