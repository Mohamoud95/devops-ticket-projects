# Ticket 001 Implementation Log

## Objective

Build a Jenkins pipeline that compiles, tests, packages, and deploys a Java application automatically after a Git commit.

## Environment

- Ubuntu Linux host
- Docker Engine 29.6.0
- Docker Compose 5.1.4
- Git 2.53.0
- Jenkins 2.541.3 in a custom container
- Maven 3.9.9
- Java 17.0.18
- Public GitHub monorepo: `Mohamoud95/devops-ticket-projects`

## Implementation timeline

1. Verified Docker, Compose, and Git installations.
2. Cloned the existing portfolio repository and entered `tickets/001-jenkins-java-pipeline`.
3. Reviewed the application, JUnit tests, Maven POM, Jenkinsfile, custom Jenkins image, and Compose service line by line.
4. Detected a monorepo working-directory defect before the first build. Added `PROJECT_DIR` and Jenkins `dir(...)` steps so Maven runs beside the ticket POM.
5. Fixed host access to Docker by adding the Ubuntu account to the `docker` group and refreshing group membership.
6. Validated Compose, built the Jenkins image, and used an ephemeral container to verify Maven and Java.
7. Started Jenkins, installed suggested plugins, created a named administrator account, and configured a Pipeline-from-SCM job.
8. Configured repository `Mohamoud95/devops-ticket-projects`, branch `main`, and script path `tickets/001-jenkins-java-pipeline/Jenkinsfile`.
9. Ran the pipeline, investigated deployment failures, and preserved the diagnostic evidence described below.
10. Achieved a successful build, verified the deployed JAR and checksum, and confirmed Jenkins test and artifact reporting.
11. Committed a third JUnit test for null input. Jenkins detected the SCM change automatically and completed build 4 successfully.

## Troubleshooting evidence

### Failure 1: Docker socket access

Symptom:

```text
permission denied while trying to connect to the Docker API at unix:///var/run/docker.sock
```

Diagnosis:

- `/var/run/docker.sock` belonged to `root:docker` with group read/write access.
- The Ubuntu account was not initially a member of the `docker` group.

Resolution:

- Appended the user to the `docker` group with `usermod -aG`.
- Refreshed membership with `newgrp docker`.
- Verified non-root Docker access with `docker info`.

Security note: Docker group membership is effectively privileged access and should be limited on shared systems.

### Failure 2: Deployment bind-mount permission

Symptom:

```text
cp: cannot create regular file '/var/jenkins_home/deployments/ticket-1-java-app.jar': Permission denied
```

Diagnosis:

- Host directory ownership was `1000:1000`.
- The container saw the same bind mount as `65534:65534`.
- Docker reported the `userns` security option.
- `/proc/self/uid_map` showed container IDs mapped from host ID `100000`.

Decision:

- Rejected `chmod 777` because it grants unnecessary global write access.
- Rejected disabling user namespaces because it weakens isolation.
- Removed the deployment bind mount and retained the artifact in the existing Docker-managed `jenkins_home` volume.

### Failure 3: Residual directory ownership

After removing the bind mount, `/var/jenkins_home/deployments` existed as `0:0` with mode `755`. Jenkins runs as `1000:1000`, so the directory remained non-writable.

Resolution:

- Changed ownership only for the deployment directory to `1000:1000`.
- Verified effective access with a non-root temporary file create/delete test.
- Reran the pipeline successfully.

## Successful evidence

### Build 3

- Result: SUCCESS
- Application output: `Hello, Jenkins!`
- Versioned JAR archived by Jenkins
- Deployment JAR stored at `/var/jenkins_home/deployments/ticket-1-java-app.jar`
- Two original JUnit tests passed

### Deployment verification

- Observed size: approximately 2.8 KiB
- SHA-256 for the verified build-3 deployment:

```text
c3e8f56db323f9b3ca7590efe9758800983f251b6e6dc9889e7ac3ac69289117a
```

### Build 4: automatic commit trigger

- Trigger: `Started by an SCM change`
- Commit message: `Test null greeting input`
- Git revision: `628788fa8689349b4e0b1fb00a842ffe66497c9e`
- Result: SUCCESS
- Duration: 23 seconds
- Tests: 3 passed, 0 failed, 0 skipped
- JAR archived and deployed

## Acceptance criteria result

| Criterion | Evidence | Result |
|---|---|---|
| Compile Java app | Maven Compile stage | Passed |
| Run automated tests | Jenkins JUnit report | 3/3 passed |
| Package application | Archived versioned JAR | Passed |
| Deploy application | Persistent deployment JAR plus smoke test | Passed |
| Run after commit | Build 4 started by SCM change | Passed |
| Maintain traceability | Git revision, artifact fingerprint, build history | Passed |

## Operational commands

Start Jenkins:

```bash
docker compose up -d
```

Check status and readiness:

```bash
docker compose ps
docker compose logs jenkins | grep -F 'Jenkins is fully up and running' | tail -1
```

Verify the deployed artifact:

```bash
docker exec ticket-1-jenkins ls -lh /var/jenkins_home/deployments/ticket-1-java-app.jar
docker exec ticket-1-jenkins sha256sum /var/jenkins_home/deployments/ticket-1-java-app.jar
```

Stop without deleting persistent data:

```bash
docker compose stop
```

Avoid `docker compose down --volumes` unless erasing Jenkins configuration and history is intentional.
