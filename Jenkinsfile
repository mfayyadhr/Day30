pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "mfayyadhr/java-openshift-jenkins"
        DOCKER_CREDENTIALS_ID = "docker-hub"
        GITHUB_REPO = "https://github.com/mfayyadhr/Day30.git"
        OPENSHIFT_PROJECT = "rmuhammadfayyadh-dev"
        OPENSHIFT_SERVER = "https://api.rm1.0a51.p1.openshiftapps.com:6443"
        OPENSHIFT_TOKEN = credentials('openshift-token-fayyadh')
        WEBHOOK_URL = "https://8ab5ba3d3dae.ngrok-free.app/github-webhook/"
    }

    stages {
        stage('Clone GitHub Repo') {
            steps {
                git url: "${env.GITHUB_REPO}", branch: 'main'
            }
        }

        stage('Set Docker Tag') {
            steps {
                script {
                    env.DOCKER_TAG = "v${env.BUILD_NUMBER}"
                    echo " Docker tag: ${env.DOCKER_TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE}:${env.DOCKER_TAG}"
                    docker.build("${DOCKER_IMAGE}:${env.DOCKER_TAG}", "-f java_openshift/Dockerfile java_openshift")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker image to Docker Hub"
                    docker.withRegistry('', "${DOCKER_CREDENTIALS_ID}") {
                        docker.image("${DOCKER_IMAGE}:${env.DOCKER_TAG}").push()
                    }
                }
            }
        }

        stage('Generate Deployment YAML') {
            steps {
                script {
                    def baseYaml = readFile('java_openshift/base-deployment.yaml')
                    def updatedYaml = baseYaml.replaceAll(
                        "__IMAGE_TAG__", env.DOCKER_TAG
                    )
                    writeFile file: 'deployment.yaml', text: updatedYaml
                    echo "YAML updated with image tag: ${env.DOCKER_TAG}"
                }
            }
        }

        stage('Apply to OpenShift') {
            steps {
                script {
                    sh """
                    oc login ${OPENSHIFT_SERVER} --token=${OPENSHIFT_TOKEN} --insecure-skip-tls-verify
                    oc project ${OPENSHIFT_PROJECT}
                    oc apply -f deployment.yaml
                    """
                }
            }
        }
    }

    post {
        success {
            script {
                def route = sh(script: "oc get route pandu-java-openshift-jenkins -o jsonpath='{.spec.host}'", returnStdout: true).trim()
                def routeUrl = "http://${route}"
                echo "Deployment successful! Access your app at: ${routeUrl}"
            }
        }

        failure {
            script {
                def payload = """
                {
                  "text": "Jenkins deployment failed for *pandu-java-openshift-jenkins* in build #${env.BUILD_NUMBER}",
                  "attachments": [
                    {
                      "color": "danger",
                      "title": "Job: ${env.JOB_NAME}",
                      "title_link": "${env.BUILD_URL}",
                      "text": "Check the Jenkins logs for more details."
                    }
                  ]
                }
                """
                writeFile file: 'alert-payload.json', text: payload
                sh "curl -X POST -H 'Content-type: application/json' --data @alert-payload.json ${env.WEBHOOK_URL}"
            }
        }
    }
}