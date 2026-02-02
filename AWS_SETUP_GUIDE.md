# AWS Account Setup Guide

To deploy this stack, you need **Administrator** credentials for your AWS account configured on your local machine.

## 1. Create an IAM User (Console)

1.  Log in to the [AWS Console](https://console.aws.amazon.com/).
2.  In the top search bar, type `IAM` and select **IAM**.
3.  In the left sidebar, click **Users**.
4.  Click the orange **Create user** button.
5.  **Step 1:**
    - **User name**: `terraform-admin` (or similar)
    - Click **Next**.
6.  **Step 2:**
    - Select **Attach policies directly**.
    - In the search box, type `AdministratorAccess`.
    - Check the box next to **AdministratorAccess** (ensure it is the AWS managed policy).
    - Click **Next**.
7.  **Step 3:**
    - Review and click **Create user**.

## 2. Generate Access Keys

1.  Click on the newly created user name (`terraform-admin`) to open its details.
2.  Click the **Security credentials** tab.
3.  Scroll down to the **Access keys** section.
4.  Click **Create access key**.
5.  Select **Command Line Interface (CLI)**.
6.  Check the confirmation box ("I understand...") and click **Next**.
7.  (Optional) Add a description tag like "Local Terraform". Click **Create access key**.
8.  **IMPORTANT:** Copy the **Access key** and **Secret access key** now. You cannot see the secret key again later.

## 3. Configure Local CLI

Open your terminal and run:

```bash
aws configure
```

Paste your credentials when prompted:

- **AWS Access Key ID**: `[Paste your Access Key, starts with AKIA...]`
- **AWS Secret Access Key**: `[Paste your Secret Key]`
- **Default region name**: `us-east-1` (Must match the region in your blueprint)
- **Default output format**: `json`

## 4. Verify

Run this command to prove you are authenticated:

```bash
aws sts get-caller-identity
```

**Success looks like:**

```json
{
  "UserId": "AIDAZ...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/terraform-admin"
}
```

**Failure looks like:**

- `Unable to locate credentials`
- `The security token included in the request is invalid`
