handler () {
    set -e
    # Parse CodePipeline Event Data
    EVENT_DATA=$1
    job_id=$(echo $EVENT_DATA | jq .[].id -r)
    bucketName=$(echo $EVENT_DATA | jq .[].data.inputArtifacts[0].location.s3Location.bucketName -r)
    artifactPath=$(echo $EVENT_DATA | jq .[].data.inputArtifacts[0].location.s3Location.objectKey -r)

    # Generate Kubeconfig
    aws eks update-kubeconfig --name shire-cluster

    # Download CodeBuild Artifact
    cd /tmp
    aws s3 cp s3://$bucketName/$artifactPath artifact.zip
    unzip artifact.zip
    
    # Run Helm to Deploy Application
    helm upgrade --install --wait --namespace dev terraria .
    
    # Report Success to CodePipeline
    aws codepipeline put-job-success-result --job-id $job_id
}
