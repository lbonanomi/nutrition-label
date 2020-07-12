#!/bin/sh -l

# Get PR stats
#
export MIX_WITH=$(curl -s -u :$TOKEN "https://api.github.com/search/issues?q=author:$GITHUB_ACTOR+is:pr+is:merged+is:public+-user:$GITHUB_ACTOR" | jq .items[].repository_url | sort | uniq | wc -l) 

export PULL_COUNT=$(curl -s -u :$TOKEN "https://api.github.com/search/issues?q=author:$GITHUB_ACTOR+is:pr+is:merged+is:public+-user:$GITHUB_ACTOR" | jq .total_count)

# Get issue stats
#
export JAM_WITH=$(curl -s -u :$TOKEN "https://api.github.com/search/issues?q=iis:issue+commenter:$GITHUB_ACTOR+-user:$GITHUB_ACTOR" | jq .items[].repository_url | sort | uniq | wc -l)

# Get language stats
#

# Include forked repos
#curl -s https://api.github.com/users/$GITHUB_ACTOR/repos | jq .[].languages_url | tr -d '"' | while read dump

# Exclude forked repos
curl -s https://api.github.com/users/$GITHUB_ACTOR/repos | jq '.[] | "\(.languages_url ) \(.fork)"' | tr -d '"' | awk '/false$/ { print $1 }' | while read dump

do
	curl -s $dump | awk '/:/ { gsub(/\"/,"");gsub(/:/,"");gsub(/,/,""); print; }' 
done > BUFF

awk '{ print $1 }' BUFF | sort | uniq | while read uniq_lang
do
	awk '$1 == "'$uniq_lang'" { a=a+$2 } END { print "'$uniq_lang'",a }'  BUFF >> STATS
done

# Count local repos
#
export REPO_COUNT=$(curl -s https://api.github.com/users/$GITHUB_ACTOR/repos | jq .[].full_name | wc -l)

# Calculate language stats
#
export LANG1_NAME=$(sort -rnk2 STATS | head -1 | awk '{ print $1 }')
export LANG1_BYTES=$(sort -rnk2 STATS | head -1 | awk '{ printf "%i KB\n", $2 / 1024 }')

export LANG2_NAME=$(sort -rnk2 STATS | head -2 | tail -1 | awk '{ print $1 }')
export LANG2_BYTES=$(sort -rnk2 STATS | head -2 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')

export LANG3_NAME=$(sort -rnk2 STATS | head -3 | tail -1 | awk '{ print $1 }')
export LANG3_BYTES=$(sort -rnk2 STATS | head -3 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')

export LANG4_NAME=$(sort -rnk2 STATS | head -4 | tail -1 | awk '{ print $1 }')
export LANG4_BYTES=$(sort -rnk2 STATS | head -4 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')

export LANG5_NAME=$(sort -rnk2 STATS | head -5 | tail -1 | awk '{ print $1 }')
export LANG5_BYTES=$(sort -rnk2 STATS | head -5 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')


# Populate template SVG with values
#
cat template.svg | envsubst | base64 > label.svg

# Get SHA of existing label
#
CURRENT_SHA=$(curl -L -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/contents/label.svg | jq .sha | tr -d '"' | head -1)

# Push new label
#
curl -s -u :$TOKEN -X PUT -d '{ "message":"Re-label", "sha":"'$CURRENT_SHA'", "content":"'$(cat label.svg | tr -d '\n\r')'"}' https://api.github.com/repos/$GITHUB_REPOSITORY/contents/label.svg

rm STATS
rm BUFF
