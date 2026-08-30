# Ticket 1: Jenkins CI/CD Pipeline for a Java App

This repository solves ticket 1 from *100 Problem-Based DevOps Projects*:

> Build a Jenkins pipeline to compile, test, and deploy a Java app automatically after each commit.

The example is intentionally small so the DevOps workflow stays visible. A Java command-line app is compiled and tested with Maven, packaged as an executable JAR, and copied into a persistent deployment folder by Jenkins.

## What the software is

- **Java 17** is the programming language and runtime. `javac` compiles source code; `java` runs compiled code.
- **Maven** is the Java build tool. It downloads declared dependencies, follows a standard project layout, compiles code, runs tests, and packages the JAR.
- **JUnit 5** is the automated testing framework.
- **Jenkins** is the automation server. It reads `Jenkinsfile` and executes the pipeline stages.
- **Docker** runs Jenkins in an isolated, reproducible container, so Jenkins and Maven do not have to be manually configured on the host.
- **Git** records changes as commits. Jenkins watches the Git repository and starts a pipeline when it detects a new commit.
- **GitHub** hosts the Git repository so Jenkins can fetch it and receive commit notifications.

## Pipeline flow

```text
Git commit -> Jenkins detects change -> Compile -> Test -> Package -> Deploy
                                             |         |
                                             |         +-> save executable JAR
                                             +-> publish JUnit results
```

If compilation or testing fails, later stages do not run. This is the safety mechanism that prevents known-broken code from being deployed.

## Repository layout

```text
.
|-- Jenkinsfile                  Pipeline as code
|-- pom.xml                      Maven project and dependency configuration
|-- Dockerfile.jenkins           Jenkins image with Maven installed
|-- compose.yaml                 Local Jenkins service definition
|-- deployments/                 Tracked placeholder for optional exported artifacts
`-- src/
    |-- main/java/.../App.java   Application code
    `-- test/java/.../AppTest.java Automated tests
```

## Step-by-step lab

### 1. Install the prerequisites

Install Docker Engine, the Docker Compose plugin, and Git. Your Ubuntu screenshot already confirms that all three are installed and available.

Check them in the Ubuntu terminal:

```bash
docker --version
docker compose version
git --version
```

`--version` asks each program to print its installed version. It is a quick way to confirm that the shell can find the program. You will reuse this diagnostic pattern for many tools, such as `java --version` and `mvn --version`.

### 2. Enter the project directory

```bash
git clone https://github.com/Mohamoud95/devops-ticket-projects.git
cd devops-ticket-projects/tickets/001-jenkins-java-pipeline
```

- `git clone` downloads the repository and its Git history from GitHub. Run it only if the repository is not already on this machine.
- `cd` means **change directory**. It enters ticket 1 so Docker Compose reads this ticket's `compose.yaml` rather than files belonging to another ticket.

### 3. Build and start Jenkins

```bash
docker compose up --build -d
```

- `docker compose` reads `compose.yaml`.
- `up` creates and starts the declared service.
- `--build` builds `Dockerfile.jenkins`, adding Maven to the Jenkins image.
- `-d` means detached mode, so the container runs in the background.

Future use: the same pattern starts local databases, monitoring stacks, or multi-service applications reproducibly.

Check the container:

```bash
docker compose ps
docker compose logs -f jenkins
```

- `ps` shows service state and exposed ports.
- `logs` shows the program output.
- `-f` follows new log lines; press `Ctrl+C` to stop following without stopping Jenkins.

### 4. Unlock Jenkins

Open <http://localhost:8080>. Retrieve the one-time administrator password:

```bash
docker exec ticket-1-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

- `docker exec` runs a command inside an already-running container.
- `ticket-1-jenkins` is the container name from `compose.yaml`.
- `cat` prints the contents of the password file.

Paste the password into Jenkins, choose **Install suggested plugins**, and create the first administrator user.

### 5. Keep the existing repository up to date

Ticket 1 is stored inside the existing `devops-ticket-projects` repository. Before starting work in an existing clone, run:

```bash
cd ~/devops-ticket-projects
git pull --ff-only
cd tickets/001-jenkins-java-pipeline
```

- `git pull` downloads new commits and updates your checked-out branch.
- `--ff-only` refuses to create an accidental merge commit when the local and remote histories have diverged.
- The second `cd` returns to the ticket directory before Docker commands are run.

For future changes to this ticket:

```bash
git status
git add tickets/001-jenkins-java-pipeline
git commit -m "Describe the ticket 1 change"
git push
```

- `git status` previews modified and staged files; use it before every commit.
- `git add` stages only ticket 1 rather than unrelated repository changes.
- `git commit -m` records the staged snapshot with a meaningful message.
- `git push` uploads the new commit to the configured GitHub remote.

Never put passwords, tokens, private keys, or `.env` secrets in Git. A Git history retains old content even after a later deletion.

### 6. Create the Jenkins pipeline job

In Jenkins:

1. Select **New Item**.
2. Enter `ticket-1-java-pipeline`.
3. Select **Pipeline**, then **OK**.
4. Under **Pipeline**, choose **Pipeline script from SCM**.
5. Set **SCM** to **Git**.
6. Enter `https://github.com/Mohamoud95/devops-ticket-projects.git` as the repository URL.
7. For a public repository, no credentials are needed. For a private repository, add a GitHub credential with minimum required access.
8. Set the branch specifier to `*/main`.
9. Set the script path to `tickets/001-jenkins-java-pipeline/Jenkinsfile` because the pipeline is inside a monorepo subdirectory.
10. Save and choose **Build Now**.

Pipeline-as-code keeps automation versioned beside the app. Future edits to `Jenkinsfile` are reviewed and rolled back exactly like application code.

Because this project lives in a monorepo, Jenkins checks out the repository root while `pom.xml` is inside `tickets/001-jenkins-java-pipeline`. The pipeline therefore sets `PROJECT_DIR` and uses Jenkins's `dir(...)` step around Maven and deployment commands. Without that working-directory change, Maven would fail with a missing-project error because it could not find the POM.

### 7. Read the first result

Open the build and then **Console Output**. A successful run passes through:

1. **Compile** - `mvn clean compile` removes old output and compiles `src/main/java`.
2. **Test** - `mvn test` compiles and runs tests under `src/test/java`; Jenkins publishes their XML reports.
3. **Package** - `mvn package -DskipTests` makes `target/ticket-1-java-app-1.0.0.jar`. Tests are skipped here only because the preceding stage already ran them.
4. **Deploy** - `cp` copies the JAR to the persistent deployment directory, then `java -jar` starts it once as a smoke test.

Confirm the deployed artifact inside the persistent Jenkins volume:

```bash
docker exec ticket-1-jenkins ls -lh /var/jenkins_home/deployments
```

`docker exec` runs `ls` inside the Jenkins container. `-l` uses a detailed format and `-h` makes file sizes easier to read. The directory is part of the Docker-managed `jenkins_home` volume, so the JAR survives container replacement without weakening Docker's user-namespace isolation.

To export the deployed JAR to the host for inspection, run:

```bash
docker cp ticket-1-jenkins:/var/jenkins_home/deployments/ticket-1-java-app.jar ./deployments/
```

`docker cp` copies a file between a container and the host. The source is the deployed JAR in persistent Jenkins storage, and the destination is the repository's local `deployments` directory. The JAR is ignored by Git.

### 8. Prove that every commit triggers the pipeline

Edit the greeting or add a test, then run:

```bash
cd ~/devops-ticket-projects
git add tickets/001-jenkins-java-pipeline
git commit -m "Change application greeting"
git push
```

The `pollSCM('H/2 * * * *')` trigger asks Jenkins to check for changes approximately every two minutes. `H` spreads jobs across the minute to avoid every Jenkins job starting simultaneously. Jenkins builds only if the repository revision changed.

For an immediate trigger, configure a GitHub webhook pointing to:

```text
https://YOUR-PUBLIC-JENKINS-URL/github-webhook/
```

Do not expose a local Jenkins server directly to the internet without HTTPS, authentication, updates, and network controls. Polling is safer for this local learning project.

### 9. Useful lifecycle commands

```bash
docker compose stop
docker compose start
docker compose down
```

- `stop` halts containers but preserves them and their data.
- `start` restarts existing stopped containers.
- `down` removes the Compose containers and network. The named Jenkins volume remains unless you explicitly add `--volumes`.

Do not run `docker compose down --volumes` unless you intend to erase Jenkins configuration, jobs, and build history for this lab.

## Definition of done

- [x] Application compiles.
- [x] All three JUnit tests pass and appear in Jenkins test results.
- [x] Jenkins archives the versioned JAR.
- [x] Jenkins copies `ticket-1-java-app.jar` into `/var/jenkins_home/deployments/` in the persistent Jenkins volume.
- [x] A new Git commit causes another pipeline run through SCM polling.
- [x] Repository is visible on GitHub with no secrets committed.

## Troubleshooting

- **`docker: command not found`:** install Docker Engine, then open a new terminal. Your screenshot confirms Docker is already available.
- **Port 8080 is already in use:** change `"8080:8080"` to `"8081:8080"` in `compose.yaml`, then browse to `http://localhost:8081`.
- **Jenkins cannot find Maven:** rebuild the custom image with `docker compose build --no-cache`, then `docker compose up -d`.
- **No revision to build:** verify the repository URL and branch specifier (`*/main`) in the Jenkins job.
- **Tests fail:** open the Test stage and read the assertion failure before changing the deployment stage.
- **Permission denied in deployments with Docker user namespaces:** avoid a host bind mount for the deployment directory. Container UID `1000` may map to a different host UID, making a host-owned directory appear as `65534:65534` inside the container. Store the JAR in the existing `jenkins_home` named volume and use `docker cp` when a host copy is required.

## Troubleshooting record: first deployment failure

The first Jenkins run compiled, tested, and packaged the application but failed during deployment with `Permission denied`. Read-only checks showed that the host directory was owned by `1000:1000` while the container saw it as `65534:65534`. Docker reported the `userns` security option and a UID map beginning at host ID `100000`, confirming user-namespace remapping.

Possible fixes included changing host ownership to the remapped UID, granting an ACL, disabling user namespaces for Jenkins, or using Docker-managed storage. This project keeps user-namespace isolation enabled and removes the deployment bind mount. The deployed JAR remains persistent in the existing `jenkins_home` named volume and can be exported explicitly with `docker cp`. This preserves a stronger security boundary and avoids host-specific UID assumptions.

After removing the bind mount, the persistent deployment directory still belonged to container root (`0:0`) from its earlier lifecycle. A scoped maintenance command changed only that directory to Jenkins UID/GID `1000:1000`, followed by a non-root create/delete write test. Build 3 then completed successfully. Build 4 was triggered automatically by the commit that added null-input test coverage; it passed all three tests and completed deployment.

See `docs/IMPLEMENTATION_LOG.md` for the evidence timeline and `docs/INTERVIEW_GUIDE.md` for concise interview-ready explanations.

## Future extensions

Replace the local copy command in the Deploy stage with one of these only after the core pipeline works:

- build and push a Docker image;
- copy the JAR to a Linux server over SSH;
- deploy to AWS Elastic Beanstalk or Azure App Service;
- deploy a container to Kubernetes;
- add SonarQube, dependency scanning, or approval gates.
