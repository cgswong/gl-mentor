#*********************************************************************************************************************
# Author - Nirmallya Mukherjee
# This program demonstrates various AWS Comprehend APIs
# This is provided as part of the training without any warrenty. Use the code at your own risk.
# https://docs.aws.amazon.com/comprehend/latest/dg/functionality.html
#*********************************************************************************************************************

import boto3
import json

comprehend = boto3.client(service_name='comprehend', region_name='us-west-2')
text = "As master Joda said - May the force be with you. Traffic usually is not good on my way to Cisco. La technologie peut vous donner du bonheur"

print("Calling DetectDominantLanguage")
print(json.dumps(comprehend.detect_dominant_language(Text = text), sort_keys=True, indent=4))

print('Calling DetectEntities')
print(json.dumps(comprehend.detect_entities(Text=text, LanguageCode='en'), sort_keys=True, indent=4))

print('Calling DetectKeyPhrases')
print(json.dumps(comprehend.detect_key_phrases(Text=text, LanguageCode='en'), sort_keys=True, indent=4))

print('Calling DetectSentiment')
print(json.dumps(comprehend.detect_sentiment(Text=text, LanguageCode='en'), sort_keys=True, indent=4))

print('Calling DetectSyntax')
print(json.dumps(comprehend.detect_syntax(Text=text, LanguageCode='en'), sort_keys=True, indent=4))

print('All done\n')

