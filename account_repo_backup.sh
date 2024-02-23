#!/bin/bash
#set -x

function jsonValue() {
    KEY=$1
    KEY2=$2
    num=$3
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print ""; printf $(i+1)}; if( -z "$KEY2"){if($i~/'$KEY2'\042/){print $(i+1)}}}}' | tr -d '"' | sed -n ${num}p; }

yesterday=$(date -d "yesterday" "+%Y-%m-%d")
filter="&q=updated_on>=$yesterday"

userName=""
password=""
workspace=""

#rewrite the arguments extraction using getopts
while getopts u:p:w:full flag
do
    case "${flag}" in
        u) userName=${OPTARG};;
        p) password=${OPTARG};;
        w) workspace=${OPTARG};;
        f) filter=""
    esac
done

if [ -z "$userName" ] || [ -z "$password" ] || [ -z "$workspace" ]
then
    echo "Usage: account_repo_backup.sh -u <username> -p <password> -w <workspace> [-full]"
    echo "Options:"
    echo "  -u <username>     Bitbucket username"
    echo "  -p <password>     Bitbucket password"
    echo "  -w <workspace>    Bitbucket workspace"
    echo "  -f                Full backup"
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

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir "$timestamp"
cd "$timestamp" || exit

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
tar -czf "$timestamp.tar.gz" "$timestamp"

# # Prepare the AWS S3 upload request
# bucket=""
# file="$timestamp.tar.gz"
# contentType="application/x-gzip"
# dateValue=$(date -u +"%a, %d %b %Y %H:%M:%S GMT")
# resource="/$bucket/$file"
# stringToSign="PUT\n\n$contentType\n$dateValue\n$resource"
# s3Key=""
# s3Secret=""
# signature=$(echo -en "$stringToSign" | openssl sha1 -hmac "$s3Secret" -binary | base64)
# url="https://$bucket.s3.amazonaws.com/$file"
#
# # Perform the upload
# curl -X PUT -T "$file" \
#   #     -H "Host: $bucket.s3.amazonaws.com" \
#   #     -H "Date: $dateValue" \
#   #     -H "Content-Type: $contentType" \
#   #     -H "Authorization: AWS $s3Key:$signature" \
#   #     "$url"

rm -rf "$timestamp"
rm -rf ListOfRepoSlug.txt

echo "Completed"
