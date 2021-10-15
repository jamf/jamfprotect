#!/bin/bash
 
# This example Bash script below does the following:
# - Obtains an access token.
# - Completes a listComputers query request that returns an insights scorecard for each computer that is noncompliant with one or more insights.
# - Creates a CSV file that lists each noncompliant insight for each computer.

# Keep the following in mind when using this script:
# - You must define the PROTECT_INSTANCE, CLIENT_ID, and PASSWORD variables to match your Jamf Protect environment. The PROTECT_INSTANCE variable is your tenant name (e.g., your-tenant), which is included in your tenant URL (e.g., https://your-tenant.protect.jamfcloud.com).
# - Only including simple GraphQL API requests in a Bash script is recommended.
# - This example script leverages the jq command-line tool to parse the JSON returned from the API request.

# After the script runs, a CSV file should be created that lists all noncompliant insights for each computer.  Please see https://docs.jamf.com/jamf-protect/documentation/API_Scripts.html for an example output.


PROTECT_INSTANCE=''
CLIENT_ID=''
PASSWORD=''
OUTPUT_CSV_FILE='failed_insights.csv'
 
access_token=$(\
    curl \
        --silent \
        --request POST \
        --header 'content-type: application/json' \
        --url "https://${PROTECT_INSTANCE}.protect.jamfcloud.com/token" \
        --data "{\"client_id\": \"$CLIENT_ID\",
              \"password\": \"${PASSWORD}\"}" \
    | jq -r '.access_token' \
)
 
read -r -d '' LIST_COMPUTERS_QUERY << 'ENDQUERY'
query listComputers($next: String) {
  listComputers(
    input: { 
      filter: {
        scorecard: {
          jsonContains: "[{\"pass\": false}]"
        }
      },
      next: $next,
      pageSize: 100
    }
  ) {
    items {
      hostName
      scorecard {
        label
        pass
        enabled
      }
    }
    pageInfo {
      next
    }
  }
}
ENDQUERY
 
echo "Retrieving paginated results:"
 
echo 'Host Name,Insight Label,Passing' > "$OUTPUT_CSV_FILE"
 
next_token='null'
page_count=1
while true; do
 
    echo "  Retrieving page $((page_count++)) of results..."
 
    request_json=$(jq -n \
        --arg q "$LIST_COMPUTERS_QUERY" \
        --argjson next_token $next_token \
        '{"query": $q, "variables": {"next": $next_token}}'
    )
 
    list_computers_resp=$(\
        curl \
            --silent \
            --request POST \
            --header "Authorization: ${access_token}" \
            --url "https://${PROTECT_INSTANCE}.protect.jamfcloud.com/graphql" \
            --data "$request_json"
        )
 
    jq -r \
        '.data.listComputers.items[]
            | {hostName: .hostName, scorecard_entry: .scorecard[]} 
            | select(.scorecard_entry.pass == false) 
            | select(.scorecard_entry.enabled == true) 
            | [.hostName, .scorecard_entry.label, .scorecard_entry.pass]
            |  @csv' \
        <<< "$list_computers_resp" \
        >> "$OUTPUT_CSV_FILE"
 
    next_token=$(jq '.data.listComputers.pageInfo.next' <<< "$list_computers_resp")
 
    [[ $next_token == "null" ]] && break
 
done
 
echo "Done. Results written to '$OUTPUT_CSV_FILE'."
 
exit 0
