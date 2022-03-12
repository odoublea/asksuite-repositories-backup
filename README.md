# README #

### What is this script for? ###

The script will perform a full backup of your workspace's repositories using `git clone --mirror <RepoURL>`

### How do I get set up? ###

* Download the [bash script](https://bitbucket.org/rtest123/repo-backup-script/raw/master/account_repo_backup.sh) and put it within a new backup directory
* Make the script executable with `chmod 777 account_repo_backup.sh`
* Run the bash script with `./account_repo_backup.sh <Username> <AppPassword> <WorkspaceID>`

### Contribution guidelines ###

* Fork the repository
* Make changes on a new branch
* Create a Pull Request