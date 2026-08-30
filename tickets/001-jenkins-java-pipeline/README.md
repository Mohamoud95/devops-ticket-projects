# Ticket 1: Jenkins CI/CD Pipeline for a Java App

This repository solves ticket 1 from *100 Problem-Based DevOps Projects By CybeCloud*:

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
|-- deployments/                 Local deployment destination
`-- src/
    |-- main/java/.../App.java   Application code
    `-- test/java/.../AppTest.java Automated tests
```

## Step-by-step lab

### 1. Install the prerequisites

Install Docker Desktop and Git. Docker Desktop supplies both the Docker engine and the `docker compose` command. On Windows, start Docker Desktop before continuing.

Check them in PowerShell:

```powershell
docker --version
docker compose version
git --version
```

`--version` asks each program to print its installed version. It is a quick way to confirm that the shell can find the program. You will reuse this diagnostic pattern for many tools, such as `java --version` and `mvn --version`.

### 2. Enter the project directory

```powershell
cd C:\path\to\ticket-1-jenkins-java-pipeline
```

`cd` means **change directory**. Commands normally operate on the current directory, so this makes the repository the current working context. Replace the example path with the actual clone location.

### 3. Build and start Jenkins

```powershell
docker compose up --build -d
```

- `docker compose` reads `compose.yaml`.
- `up` creates and starts the declared service.
- `--build` builds `Dockerfile.jenkins`, adding Maven to the Jenkins image.
- `-d` means detached mode, so the container runs in the background.

Future use: the same pattern starts local databases, monitoring stacks, or multi-service applications reproducibly.

Check the container:

```powershell
docker compose ps
docker compose logs -f jenkins
```

- `ps` shows service state and exposed ports.
- `logs` shows the program output.
- `-f` follows new log lines; press `Ctrl+C` to stop following without stopping Jenkins.

### 4. Unlock Jenkins

Open <http://localhost:8080>. Retrieve the one-time administrator password:

```powershell
docker exec ticket-1-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

- `docker exec` runs a command inside an already-running container.
- `ticket-1-jenkins` is the container name from `compose.yaml`.
- `cat` prints the contents of the password file.

Paste the password into Jenkins, choose **Install suggested plugins**, and create the first administrator user.

### 5. Push the repository to GitHub

Create an empty GitHub repository named `ticket-1-jenkins-java-pipeline` without adding a README or `.gitignore,` because those files already exist here. Then run:

```powershell
git init
git add .
git status
git commit -m "Build ticket 1 Jenkins Java pipeline"
git branch -M main
git remote add origin https://github.com/Mohamoud95/ticket-1-jenkins-java-pipeline.git
git push -u origin main
```

- `git init` creates local Git metadata in `.git`.
- `git add .` stages the current files for the next snapshot.
- `git status` previews what will be committed; use it often before commits.
- `git commit -m` saves the staged snapshot with a meaningful message.
- `git branch -M main` renames the current branch to `main`.
- `git remote add origin ...` gives the GitHub repository the conventional local name `origin`.
- `git push -u origin main` uploads `main`; `-u` records the upstream so later `git push` is sufficient.

Never put passwords, tokens, private keys, or `.env` secrets in Git. A Git history retains old content even after a later deletion.

### 6. Create the Jenkins pipeline job

In Jenkins:

1. Select **New Item**.
2. Enter `ticket-1-java-pipeline`.
3. Select **Pipeline**, then **OK**.
4. Under **Pipeline**, choose **Pipeline script from SCM**.
5. Set **SCM** to **Git**.
6. Enter the GitHub repository URL.
7. For a public repository, no credentials are needed. For a private repository, add a GitHub credential with minimum required access.
8. Set the branch specifier to `*/main`.
9. Keep the script path as `Jenkinsfile`.
10. Save and choose **Build Now**.

Pipeline-as-code keeps automation versioned beside the app. Future edits to `Jenkinsfile` are reviewed and rolled back exactly like application code.

### 7. Read the first result

Open the build and then **Console Output**. A successful run passes through:

1. **Compile** - `mvn clean compile` removes old output and compiles `src/main/java`.
2. **Test** - `mvn test` compiles and runs tests under `src/test/java`; Jenkins publishes their XML reports.
3. **Package** - `mvn package -DskipTests` makes `target/ticket-1-java-app-1.0.0.jar`. Tests are skipped here only because the preceding stage already ran them.
4. **Deploy** - `cp` copies the JAR to the persistent deployment directory, then `java -jar` starts it once as a smoke test.

Confirm the deployed artifact from PowerShell:

```powershell
Get-ChildItem .\deployments
```

`Get-ChildItem` lists directory contents. In PowerShell, `dir` and `ls` are aliases for the same command.

### 8. Prove that every commit triggers the pipeline

Edit the greeting or add a test, then run:

```powershell
git add .
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

```powershell
docker compose stop
docker compose start
docker compose down
```

- `stop` halts containers but preserves them and their data.
- `start` restarts existing stopped containers.
- `down` removes the Compose containers and network. The named Jenkins volume remains unless you explicitly add `--volumes`.

Do not run `docker compose down --volumes` unless you intend to erase Jenkins configuration, jobs, and build history for this lab.

## Definition of done

- [ ] Application compiles.
- [ ] Both JUnit tests pass and appear in Jenkins test results.
- [ ] Jenkins archives the versioned JAR.
- [ ] Jenkins copies `ticket-1-java-app.jar` into `deployments/`.
- [ ] A new Git commit causes another pipeline run.
- [ ] Repository is visible on GitHub with no secrets committed.

## Troubleshooting

- **`docker` is not recognized:** install/start Docker Desktop, close PowerShell, and open a new PowerShell window.
- **Port 8080 is already in use:** change `"8080:8080"` to `"8081:8080"` in `compose.yaml`, then browse to `http://localhost:8081`.
- **Jenkins cannot find Maven:** rebuild the custom image with `docker compose build --no-cache`, then `docker compose up -d`.
- **No revision to build:** verify the repository URL and branch specifier (`*/main`) in the Jenkins job.
- **Tests fail:** open the Test stage and read the assertion failure before changing the deployment stage.
- **Permission denied in deployments:** confirm that Compose mounted `./deployments` at `/var/jenkins_home/deployments`.

## Future extensions

Replace the local copy command in the Deploy stage with one of these only after the core pipeline works:

- build and push a Docker image;
- copy the JAR to a Linux server over SSH;
- deploy to AWS Elastic Beanstalk or Azure App Service;
- deploy a container to Kubernetes;
- add SonarQube, dependency scanning, or approval gates.
