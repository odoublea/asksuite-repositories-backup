# Bitbucket Repository Backup

## Description

This Bash script automates the backup process for repositories hosted on Bitbucket. It clones each repository in the specified Bitbucket workspace, compresses them into a single archive, and uploads the archive to an Amazon S3 bucket for safekeeping.

## Prerequisites

- Bash shell environment
- AWS CLI installed and configured with appropriate credentials
- cURL installed

## Usage

```bash
./account_repo_backup.sh -u <username> -p <password> -w <workspace> [-full]
```

### Options:

- `-u <username>`: Bitbucket username.
- `-p <password>`: Bitbucket password.
- `-w <workspace>`: Bitbucket workspace.
- `-f`: Full backup (optional). If this parameter is not provided, the script will only backup the repositories that have been updated in the day before the script is executed. If it is provided, the script will backup all repositories in the workspace.

## How It Works

1. The script retrieves a list of repository slugs from the Bitbucket API based on the provided workspace.
2. It clones each repository into a temporary folder.
3. The cloned repositories are compressed into a single archive.
4. The archive is uploaded to an Amazon S3 bucket.
5. Finally, the script cleans up temporary files.

## Example

```bash
./account_repo_backup.sh -u myusername -p mypassword -w myworkspace
```

## Notes

- The script utilizes `getopts` for argument parsing, ensuring proper usage.
- It makes use of the Bitbucket API and AWS CLI for repository and file handling.
- Ensure that the AWS CLI is properly configured with appropriate permissions to access the specified S3 bucket.

## Contributors

guilherme.tiscoski
