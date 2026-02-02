# Apply Readiness Checklist

## 1. Prerequisites (Local)

- [ ] **AWS CLI** installed and configured (`aws configure` or `aws sso login`) with **AdministratorAccess**.
- [ ] **Terraform** (v1.5+) installed.
- [ ] **Git** installed and repo initialized (`git init`).

## 2. Infrastructure Bootstrap (One-Time)

**Directory:** `infra/bootstrap`

1.  Identify your GitHub Repo (e.g., `jakeg/gergen-stack`).
2.  Run `terraform init`
3.  Run `terraform apply -var="github_repository=jakeg/gergen-stack"`
4.  **Record Outputs:**
    - `s3_bucket_name` (e.g., `gergen-stack-tf-state`)
    - `dynamodb_table_name`
    - `github_actions_role_arn` (This is the value for `AWS_ROLE_ARN` secret)

## 3. Environment Provisioning (All Envs)

Apply environments in order:

### A. Dev
**Directory:** `infra/environments/dev`
1.  Run `terraform init`
2.  Run `terraform apply`
3.  **Record Outputs** for GitHub Vars (Dev).

### B. Test (Empty Shell to Start)
**Directory:** `infra/environments/test`
1.  Run `terraform init`
2.  Run `terraform apply`
3.  **Record Outputs** for GitHub Vars (Test).

### C. Prod (Empty Shell to Start)
**Directory:** `infra/environments/prod`
1.  Run `terraform init`
2.  Run `terraform apply`
3.  **Record Outputs** for GitHub Vars (Prod).

## 4. GitHub Configuration

### Secrets
- [ ] `AWS_ROLE_ARN`: Value from Bootstrap output `github_actions_role_arn`.

### Variables (Global)
- [ ] `ARTIFACT_BUCKET`: Value from Dev output `artifact_bucket_name`.
- [ ] `EB_APP_NAME`: Value from Dev output `api_beanstalk_app_name`.

### Variables (Per Environment)
For each environment (Dev, Test, Prod), output mapping:
- `WEB_BUCKET` <- `web_s3_bucket_name`
- `CF_DIST_ID` <- `web_cloudfront_distribution_id`
- `EB_ENV_NAME` <- `api_beanstalk_env_name`
- `API_URL` <- `api_base_url`

**Example Naming Convention in GitHub:**
- `DEV_WEB_BUCKET`
- `TEST_WEB_BUCKET`
- `PROD_WEB_BUCKET`
etc.

## 5. First Deployment

1.  Commit and Push to `main`.
2.  Watch GitHub Actions `Deploy to Dev` workflow.
3.  Verify success.

## 6. Artifact Pattern Confirmation
The system relies on this EXACT path structure in S3. Do not change manually.
- **Backend:** `s3://${ARTIFACT_BUCKET}/backend/${SHORT_SHA}.jar`
- **Frontend:** `s3://${ARTIFACT_BUCKET}/frontend/${SHORT_SHA}.zip`

## 7. Migration Policy (Production)
**Start-up Auto-Migration**:
- Migrations run automatically when the Spring Boot application starts.
- **Strict Requirement**: All migrations must be **backward compatible**.
- **Rollback**: If migration fails, app fails to start, Beanstalk performs rolling update failure, previous version remains live.
- **Risk**: Database state is mutated before app success is confirmed. Bad migration requires manual fix (SQL) or snapshot restore.

## 8. Verification (Post-Deploy)

### API Smoke Test
```bash
curl -i http://<api_beanstalk_cname>/api
# Expect:
# HTTP/1.1 200 OK
# Content-Type: application/json
# { "status": "ok", "service": "gergen-stack-api", "version": "1.0.0" }
```

### API Health Check
```bash
curl -i http://<api_beanstalk_cname>/actuator/health
# Expect: { "status": "UP" }
```

### Frontend Verification
1.  Open `https://<web_cloudfront_domain_name>` in browser.
2.  Confirm "Gergen Stack: dev" is visible.
3.  Confirm "Backend Status" shows JSON response (matches health check).
```
