#!/bin/bash
#set -x

function jsonValue() {
    KEY=$1
    KEY2=$2
    num=$3
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print ""; printf $(i+1)}; if( -z "$KEY2"){if($i~/'$KEY2'\042/){print $(i+1)}}}}' | tr -d '"' | sed -n ${num}p; }

userName=$1
password=$2
accountName=$3

echo "Getting Repositories size"
size="$(curl -s -u "$userName:$password" "https://api.bitbucket.org/2.0/repositories/$accountName?pagelen=100&page=100000" | jsonValue slug size 1)"
echo "Number of repositories: $size"
echo ""
echo "Getting Repositories slug"

yesterday=$(date -d "yesterday" "+%Y-%m-%d")
echo "Yesterday: $yesterday"

curl -s -u "$userName:$password" "https://api.bitbucket.org/2.0/repositories/$accountName?pagelen=100&page=1&q=updated_on>=$yesterday" | jsonValue full_name null  | sed -n -e "/$accountName/p" >> ListOfRepoSlug.txt

sort -u -o ListOfRepoSlug.txt ListOfRepoSlug.txt
grep -v '^$' ListOfRepoSlug.txt > ListOfRepoSlug_temp.txt
mv ListOfRepoSlug_temp.txt ListOfRepoSlug.txt

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
#     -H "Host: $bucket.s3.amazonaws.com" \
#     -H "Date: $dateValue" \
#     -H "Content-Type: $contentType" \
#     -H "Authorization: AWS $s3Key:$signature" \
#     "$url"

rm -rf "$timestamp"
rm -rf ListOfRepoSlug.txt

echo "Completed"
