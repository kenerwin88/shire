handler () {
    set -e
    pwd
    EVENT_DATA=$1
    echo $EVENT_DATA
    aws eks update-kubeconfig --name shire-cluster
    # kubectl get pods --all-namespaces
    # helm list
    job_id=$(echo $EVENT_DATA | jq .[].id -r)
    bucketName=$(echo $EVENT_DATA | jq .[].data.inputArtifacts[0].location.s3Location.bucketName -r)
    artifactPath=$(echo $EVENT_DATA | jq .[].data.inputArtifacts[0].location.s3Location.objectKey -r)
    cd /tmp
    aws s3 cp s3://$bucketName/$artifactPath artifact.zip
    unzip artifact.zip
    ls
    helm upgrade --install --wait --namespace dev terraria .
    aws codepipeline put-job-success-result --job-id $job_id
}