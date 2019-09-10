var aws = require('aws-sdk');
let path = require('path');
let {readFileSync} = require('fs');

var cloudfront = new aws.CloudFront();

const params = path.resolve('params.json');
const configString = readFileSync(params).toString();
const config = JSON.parse(configString);

exports.handler = async function (event, context) {
  
    var bucket = event.Records[0].s3.bucket.name;
    var key = event.Records[0].s3.object.key;

    key = key.replace(/^\//,"");

    let dists = await cloudfront.listDistributions().promise();

    let pathPrefix = config.pathPrefix;
    
    if(!pathPrefix){
        pathPrefix = '';
    } else {
        pathPrefix = pathPrefix.replace(/\/$/,"");
    }


    for (let i = 0; i < dists.DistributionList.Items.length; i++) {
        const dist = dists.DistributionList.Items[i];

        for (let j = 0; j < dist.Origins.Items.length; j++) {

            const origin = dist.Origins.Items[j];

            if (origin.DomainName.indexOf(bucket) != 0) {
                continue;
            }
            
            var pathes = [];

            pathes.push( pathPrefix + '/'+ key);

            if(key === 'index.html'){
                pathes.push('/');
            }

            var request = {
                DistributionId : dist.Id,
                InvalidationBatch : {
                    CallerReference : '' + new Date().getTime(),
                    Paths : {
                        Quantity : pathes.length,
                        Items : pathes
                    }
                }
            };

            await cloudfront.createInvalidation(request).promise();

        }
    }
}