# Gergen Stack Runbook

## 1. Initial Setup (Bootstrap)

Before running the infrastructure pipelines or local development, you must bootstrap the Terraform state.

1.  **Credentials:** Ensure you have AWS credentials with Admin permissions.
2.  **Bootstrap:**
    ```bash
    cd infra/bootstrap
    terraform init
    terraform apply
    # Output: s3_bucket_name, dynamodb_table_name
    ```
    This creates the S3 bucket and DynamoDB table used for remote state locking.

## 2. Infrastructure Deployment

To deploy the **Dev** environment:

```bash
cd infra/environments/dev
terraform init
terraform apply
```

**Important:** Note the `outputs`.
- `api_beanstalk_cname`: The raw URL of your backend.
- `web_s3_bucket_name`: The bucket for frontend code.
- `web_cloudfront_domain_name`: The public URL of your website.
- `secrets_manager_db_secret_name`: Name of the secret credential.

## 3. GitHub Actions Configuration

You must configure the following **Variables** and **Secrets** in your GitHub Repository settings.

### Secrets
- `AWS_ROLE_ARN`: The IAM Role ARN for GitHub Actions OIDC (You need to create this manually or via an OIDC Terraform module).

### Variables (Environment Variables)
- `ARTIFACT_BUCKET`: The name of the S3 bucket created by the stack for artifacts (see Terraform output `artifact_bucket_name` - *Wait, I added this to outputs.tf*).
- `EB_APP_NAME`: `gergen-stack-dev-app` (check TF output).

**Dev Environment:**
- `DEV_EB_ENV_NAME`: `gergen-stack-dev-env`
- `DEV_WEB_BUCKET`: `gergen-stack-dev-web`
- `DEV_CF_DIST_ID`: CloudFront ID (TF output).
- `DEV_API_URL`: `http://<api_beanstalk_cname>/api`

**Test Environment:**
- `TEST_EB_ENV_NAME`, `TEST_WEB_BUCKET`, etc.

## 4. Local Development

### Backend (API)
1.  **Start DB:**
    ```bash
    docker-compose up -d db
    ```
2.  **Run App:**
    ```bash
    cd api
    ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
    ```
    API will be available at `http://localhost:8080/api`.
    Swagger/OpenAPI (if added) at `http://localhost:8080/swagger-ui.html`.

### Frontend (Web)
1.  **Run App:**
    ```bash
    cd web
    npm install
    npm run dev
    ```
    Web will be at `http://localhost:5173`.
    It is configured to talk to `http://localhost:8080` via `public/config.js`.

## 5. Promotion Workflow

1.  **Dev:** Push code to `main`. GitHub Actions automatically deploys to Dev.
2.  **Test:**
    - Go to GitHub Actions -> "Promote to Test" workflow.
    - Click "Run workflow".
    - Enter the **Short Commit SHA** (e.g., `a1b2c3d`) of the built artifact you want to promote.
    - Click Run.
3.  **Prod:** Similar to Test (create the workflow `promote-prod.yml` following the `promote-test.yml` pattern).

## 6. Database Migrations

### Policy: Automatic Strict Backward Compatibility
- **Config**: Migrations are embedded in the App JAR (`src/main/resources/db/migration`).
- **Execution**: Runs automatically on application startup (Spring Boot `flyway.enabled=true`).
- **Production Safety**:
    - All migrations **MUST** be backward compatible (e.g., add column (nullable), populate data, switch code, remove column in later deploy).
    - If a migration fails: The new application version will fail to start. Beanstalk will stop the deployment. The database, however, might be in a failed migration state.
- **Recovery**:
    - Connect to DB (via Bastion/VPN).
    - Fix the issue manually or remove the failed row from `flyway_schema_history`.
    - Redeploy.
- **Rule:** Never modify an existing migration file (`V1__...`). Always add a new version (`V2__...`).

## 7. Secrets Rotation

To rotate the DB password:
1.  Go to AWS Secrets Manager.
2.  Update the Secret Value (new password).
3.  Restart the Elastic Beanstalk Environment (it fetches secrets on startup/env injection).
