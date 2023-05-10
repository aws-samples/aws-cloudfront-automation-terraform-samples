import boto3
import os
import time
import json
import sys

CloudfrontClient = boto3.client('cloudfront')


def lambda_handler(event, context):
    # Get the cloudfront configuration
    loadBalancerName = (event['detail']['responseElements']['loadBalancers'][0]['loadBalancerName'])
    loadBalancerDNSName = (event['detail']['responseElements']['loadBalancers'][0]['dNSName'])
    distributionId = os.environ['cloudfront_distribution_id']

    Etag = CloudfrontClient.get_distribution_config(
        Id=distributionId  ## Pre defined value
    )["ETag"]

    getDistristribution = CloudfrontClient.get_distribution_config(Id=distributionId)["DistributionConfig"]

    NumberofOrigin = getDistristribution["Origins"]["Quantity"]
    count = NumberofOrigin - 1

    for count in range(NumberofOrigin):
        Originid = getDistristribution["Origins"]["Items"][count]["Id"]
        if loadBalancerName in Originid:
            print('s1 and s2 are equal')
            getDistristribution["Origins"]["Items"][count]["DomainName"] = loadBalancerDNSName
            response = CloudfrontClient.update_distribution(DistributionConfig=getDistristribution, Id=distributionId,
                                                            IfMatch=Etag)
            break
    else:
        print("Cannot find mapping in Cloudfront")
        raise