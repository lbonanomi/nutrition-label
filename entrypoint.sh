#!/bin/sh -l

[[ -n "$TOKEN" ]] || printf '\e[1;31m%-6s\e[m' "Create a secret called \"TOKEN\" with write permission to $GITHUB_REPOSITORY\n"
[[ -n "$TOKEN" ]] || exit 1


# Get PR stats
#

printf '\e[1;32m%-6s\e[m\n' "Counting collaborating repos"
export MIX_WITH=$(curl -s -u :$TOKEN "https://api.github.com/search/issues?q=author:$GITHUB_ACTOR+is:pr+is:merged+is:public+-user:$GITHUB_ACTOR" | jq .items[].repository_url | awk -F"/" '{ print $5 }' | sort | uniq | wc -l) 

printf '\e[1;32m%-6s\e[m\n' "Counting opened PRs"
export PULL_COUNT=$(curl -s -u :$TOKEN "https://api.github.com/search/issues?q=author:$GITHUB_ACTOR+is:pr+is:merged+is:public+-user:$GITHUB_ACTOR" | jq .total_count)

# Get issue stats
#
printf '\e[1;32m%-6s\e[m\n' "Counting opened issues"
export JAM_WITH=$(curl -s -u :$TOKEN "https://api.github.com/search/issues?q=iis:issue+commenter:$GITHUB_ACTOR+-user:$GITHUB_ACTOR" | jq .items[].repository_url | sort | uniq | wc -l)

# Get language stats
#

if [[ $1 == "true" ]]
then
	# Include forked repos
	curl -s https://api.github.com/users/$GITHUB_ACTOR/repos | jq -r .[].languages_url | while read dump
	do
		curl -s $dump | awk '/:/ { gsub(/\"/,"");gsub(/:/,"");gsub(/,/,""); print; }'
	done > BUFF
else
	# Exclude forked repos
	curl -s https://api.github.com/users/$GITHUB_ACTOR/repos | jq -r '.[] | "\(.languages_url ) \(.fork)"' | awk '/false$/ { print $1 }' | while read dump
	do
		curl -s $dump | awk '/:/ { gsub(/\"/,"");gsub(/:/,"");gsub(/,/,""); print; }' 
	done > BUFF
fi

printf '\e[1;32m%-6s\e[m\n' "Tallying lngauges"
awk '{ print $1 }' BUFF | sort | uniq | while read uniq_lang
do
	awk '$1 == "'$uniq_lang'" { a=a+$2 } END { print "'$uniq_lang'",a }'  BUFF >> STATS
done

# Count local repos
#
printf '\e[1;32m%-6s\e[m\n' "Tallying user's repositories"
export REPO_COUNT=$(curl -s https://api.github.com/users/$GITHUB_ACTOR/repos | jq .[].full_name | wc -l)

# Calculate language stats
#

printf '\e[1;32m%-6s\e[m\n' "Calculating language use"

# Get percentage-of-all-repos
#

TOTAL=$(awk '{ total=total+$2 } END { print total }' STATS)

awk '{ print $1 }' STATS | sort | uniq | while read lang
do
        printf "$lang\t"
        awk '/'"$lang"'/ { total=total+$2 } END { print (total * 100) / '"$TOTAL"' }' STATS
done > PCT

cat PCT

###

export LANG1_NAME=$(sort -rnk2 STATS | head -1 | awk '{ print $1 }')
export LANG1_BYTES=$(sort -rnk2 STATS | head -1 | awk '{ printf "%i KB\n", $2 / 1024 }')
export LANG1_PCT=$(grep $LANG1_NAME PCT | awk '{ printf "%d", $2 }')

export LANG2_NAME=$(sort -rnk2 STATS | head -2 | tail -1 | awk '{ print $1 }')
export LANG2_BYTES=$(sort -rnk2 STATS | head -2 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')
export LANG2_PCT=$(grep $LANG2_NAME PCT | awk '{ printf "%d", $2 }')

export LANG3_NAME=$(sort -rnk2 STATS | head -3 | tail -1 | awk '{ print $1 }')
export LANG3_BYTES=$(sort -rnk2 STATS | head -3 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')
export LANG3_PCT=$(grep $LANG3_NAME PCT | awk '{ printf "%d", $2 }')

export LANG4_NAME=$(sort -rnk2 STATS | head -4 | tail -1 | awk '{ print $1 }')
export LANG4_BYTES=$(sort -rnk2 STATS | head -4 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')
export LANG4_PCT=$(grep $LANG4_NAME PCT | awk '{ printf "%d", $2 }')

export LANG5_NAME=$(sort -rnk2 STATS | head -5 | tail -1 | awk '{ print $1 }')
export LANG5_BYTES=$(sort -rnk2 STATS | head -5 | tail -1 | awk '{ printf "%i KB\n", $2 / 1024 }')
export LANG5_PCT=$(grep $LANG5_NAME PCT | awk '{ printf "%d", $2 }')

# Populate template SVG with values
#
printf '\e[1;32m%-6s\e[m\n' "Building SVG"
curl -s https://raw.githubusercontent.com/lbonanomi/nutrition-label/main/template.svg | envsubst | base64 > label.svg

# Get SHA of existing label
#
printf '\e[1;32m%-6s\e[m\n' "Getting SHA of current SVG"
CURRENT_SHA=$(curl -L -s -u :$TOKEN https://api.github.com/repos/$GITHUB_REPOSITORY/contents/label.svg | jq -r .sha | head -1)

# Push new label
#
printf '\e[1;32m%-6s\e[m\n' "Publishing SVG"
curl -s -u :$TOKEN -X PUT -d '{ "message":"Re-label", "sha":"'$CURRENT_SHA'", "content":"'$(cat label.svg | tr -d '\n\r')'"}' https://api.github.com/repos/$GITHUB_REPOSITORY/contents/label.svg | jq .content.html_url

rm STATS
rm BUFF
