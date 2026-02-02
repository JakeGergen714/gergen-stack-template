# Blueprint Notes

## 1. Core Architectural Decisions

### Trunk-Based Development & Artifact Promotion
**Decision:** We use a single `main` branch with short-lived feature branches. We build artifacts exactly *once* (on merge to main) and promote that binary/bundle through environments.
**Why:**
- **Consistency:** Ensures exactly what was tested in Dev/Test is what runs in Prod. Eliminates "works on my machine" or "build drift" issues where dependency versions change between env builds.
- **Speed:** Promotion is a copy/deploy operation, not a rebuild operation.

### Elastic Beanstalk (Backend)
**Decision:** Use AWS Elastic Beanstalk (running Java SE) for the backend instead of Kubernetes or raw EC2.
**Why:**
- **Simplicity:** "boring" default. Handles auto-scaling, load balancing, and rolling updates out of the box with minimal config.
- **Reversibility:** Logic is just a Spring Boot JAR. Can be easilycontainerized and moved to ECS/EKS later if complexity demands it.

### No API Gateway (Default)
**Decision:** The Application Load Balancer (ALB) provided by Elastic Beanstalk serves traffic directly.
**Why:**
- **Cost & Complexity:** API Gateway adds cost and configuration overhead (CORS, timeouts, mapping) that isn't strictly necessary for a "Hello World" production stack.
- **Toggle:** The architecture allows putting an API Gateway in front of the ALB later for easier rate limiting or extensive API key management.

## 2. Environment Strategy

### Hierarchy
1.  **Local:** Docker Desktop. Mocks cloud services where possible. Fastest loop.
2.  **Dev:** The "Bleeding Edge". Deploys happen automatically on every merge. Integration tests run here. Data is ephemeral/synthetic.
3.  **Test:** The "Staging" ground. Deploys are manual promotions of stable Dev builds. Used for QA sign-off.
4.  **Prod:** The "Live" environment. Deploys are manual promotions of signed-off Test builds.

### Frontend "Build Once"
React apps typically bake environment variables (like `REACT_APP_API_URL`) into the HTML/JS at build time. To support artifact promotion (moving the same JS files from Dev -> Test -> Prod), we use **Runtime Configuration**.
- **How:** A `config.js` or `env-config.js` file is generated/updated during the *deploy* step (not the build step) and placed in the S3 bucket. The React app loads this file globally on startup.

## 3. Database & Migrations

### Flyway Strategy
**Decision:** Flyway is embedded in the application.
**Safety in Prod:**
- Migrations run automatically on application startup.
- **Constraint:** All DB changes must be **Backward Compatible**.
    - *Example:* To rename a column: 1. Add new column (deploy) -> 2. Copy data (script) -> 3. Switch code to new column (deploy) -> 4. Drop old column (next deploy).
- If a migration fails, the application fails to start (Beanstalk health check fails), and the deployment rolls back automatically (immutable deployments).

## 4. Security Defaults

### Secrets
- No `.env` files with secrets in Git.
- **DB Credentials:** Stored in AWS Secrets Manager. App retrieves them at runtime.
- **Config:** Stored in AWS SSM Parameter Store (cheaper, good for non-secrets).

### Authentication
- Defaulting to **Keycloak** (OIDC/OAuth2).
- The Backend acts as a **Resource Server** (validates JWTs).
- **Toggle:** In `local` profile, we may allow a "Dev Security Configuration" that bypasses auth or accepts a hardcoded developer token, but `dev` (cloud) strictly enforces valid JWTs.

## 5. Future Toggles (What to change later)

- **Containerization:** Migrate from Beanstalk JAR -> ECS Fargate. Blueprint structure supports this by just changing the `backend.deploy_target`.
- **API Gateway:** Add AWS API Gateway in front of Beanstalk ALB.
- **Multi-Account:** Switch `aws.account_strategy` to separate AWS accounts per environment for stricter isolation (requires Terraform adjustment).
