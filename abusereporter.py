import json
import sys
import random
import requests
if __name__ == '__main__':
    url = "https://hooks.slack.com/services/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"
    developerurl = sys.argv[1]
    fileurl =sys.argv[2]
    findingscount= sys.argv[3]
    reporturl= sys.argv[4]
    assetname= sys.argv[5]
    developeremail= sys.argv[6]

    message = (f"*Asset:* {assetname} \n *Commit Type:* Code \n *Developer:* {developerurl} \n *Developer Email:* {developeremail} \n *FileURL:* {fileurl} \n *Sensitive Findings:* {findingscount}")
    title = ("Developer has committed  Org code on Public Github repo.")

    slack_data = {


	"blocks": [
		{
			"type": "section",
			"text": {
				"type": "plain_text",
				"text": title
				
			}
		},
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": message
			}
		},
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": "The file has been scanned for sensitive information."
			},
			"accessory": {
				"type": "button",
				"text": {
					"type": "plain_text",
					"text": "View Report"
					
				},
				"value": "click_me_123",
				"url": reporturl,
				"action_id": "button-action"
			}
		},
		{
			"type": "divider"
		}
	]
}
    byte_length = str(sys.getsizeof(slack_data))
    headers = {'Content-Type': "application/json", 'Content-Length': byte_length}
    response = requests.post(url, data=json.dumps(slack_data), headers=headers)
    if response.status_code != 200:
        raise Exception(response.status_code, response.text)
