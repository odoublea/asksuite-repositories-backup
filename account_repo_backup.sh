#!/bin/bash
#set -x

function jsonValue() {
    KEY=$1
    KEY2=$2
    num=$3
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print ""; printf $(i+1)}; if( -z "$KEY2"){if($i~/'$KEY2'\042/){print $(i+1)}}}}' | tr -d '"' | sed -n ${num}p; }

yesterday=$(date -d "yesterday" "+%Y-%m-%d")
echo "Yesterday: $yesterday"
filter="&q=updated_on>=$yesterday"

userName=""
password=""
workspace=""
bucket_name=""

#rewrite the arguments extraction using getopts
while getopts u:p:w:b:f flag
do
    case "${flag}" in
        u) userName=${OPTARG} ;;
        p) password=${OPTARG} ;;
        w) workspace=${OPTARG} ;;
        b) bucket_name=${OPTARG} ;;
        f) filter=""
    esac
done

if [ -z "$userName" ] || [ -z "$password" ] || [ -z "$workspace" ] || [ -z "$bucket_name" ]
then
    echo "Usage: account_repo_backup.sh -u <username> -p <password> -w <workspace> -b <bucket_name> [-full]"
    echo "Options:"
    echo "  -u <username>     Bitbucket username"
    echo "  -p <password>     Bitbucket password"
    echo "  -w <workspace>    Bitbucket workspace"
    echo "  -b <bucket_name>  AWD S3 bucket name"
    echo "  -f (optional)     Full backup"
    exit 1
fi

size_url="https://api.bitbucket.org/2.0/repositories/$workspace?pagelen=100&page=100000$filter"

echo "Getting Repositories size"
size="$(curl -s -u "$userName:$password" $size_url | jsonValue slug size 1)"
echo "Number of repositories: $size"


count=1
while true
do
    repos_url="https://api.bitbucket.org/2.0/repositories/$workspace?pagelen=100&page=$count$filter"
    echo "Getting Repositories slug from $repos_url"
    curl -s -u "$userName:$password" $repos_url | jsonValue full_name null  | sed -n -e "/$workspace/p" >> ListOfRepoSlug.txt
    count=$(($count+1))
    size=$(($size-100))
    if (("$size" <= "0")); then
        break
    fi
done

sort -u -o ListOfRepoSlug.txt ListOfRepoSlug.txt
grep -v '^$' ListOfRepoSlug.txt > ListOfRepoSlug_temp.txt
mv ListOfRepoSlug_temp.txt ListOfRepoSlug.txt
cat ListOfRepoSlug.txt | wc -l

temp_folder=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir "$temp_folder"
cd "$temp_folder" || exit

file=../ListOfRepoSlug.txt
count=1
while IFS= read line;
do
    line="$(echo -e "${line}" | tr -d '[:space:]')";
    printf "$count. Cloning $line \n"
    git clone --mirror https://$userName:$password@bitbucket.org/$line
    printf "Completed\n"
    count=$(($count+1))
done <"$file"

cd ..
backup_type=""

if [ -z "$filter" ]
then
    backup_type="full"
else
    backup_type="daily"
fi

compressed_file="$workspace-$backup_type-$yesterday.tar.gz"
tar -czf "$compressed_file" "$temp_folder"

# Upload file to S3
aws s3 cp "$compressed_file" "s3://$bucket_name/$compressed_file"

rm -rf "$temp_folder"
rm -rf "$compressed_file"
rm -rf ListOfRepoSlug.txt


# check if upload was successful using the getobject command
result=$(aws s3api head-object --bucket "$bucket_name" --key "$compressed_file" 2>&1)

if [[ $? -eq 0 ]]; then
    echo "File exists in the bucket."
else
    echo "File does not exist in the bucket."
    exit 1
fi

echo "Completed"
