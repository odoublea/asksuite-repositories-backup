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
#echo $userName
#echo $password
#echo $accountName

echo "Getting Repositories size"
size="$(curl -s -u "$userName:$password" "https://api.bitbucket.org/2.0/repositories/$accountName?pagelen=100&page=100000" | jsonValue slug size 1)"
echo "Number of repositories: $size"
echo ""
echo "Getting Repositories slug"

count=1
while true
do
curl -s -u "$userName:$password" "https://api.bitbucket.org/2.0/repositories/$accountName?pagelen=100&page=1" | jsonValue full_name null  | sed -n -e "/$accountName/p" >> ListOfRepoSlug.txt
	count=$(($count+1))
	size=$(($size-10))
	if (("$size" <= "0")); then
    	break
    fi
done

sed -i '/^$/d' ListOfRepoSlug.txt
echo "" >> ListOfRepoSlug.txt

file=ListOfRepoSlug.txt
count=1
while IFS= read line; 
do 
   line="$(echo -e "${line}" | tr -d '[:space:]')";
   printf "$count. Cloning $line \n"
   git clone --mirror https://$userName:$password@bitbucket.org/$line
   printf "Completed\n"
   count=$(($count+1))   
done <"$file"
echo "Completed"
