pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "mfayyadhr/java-openshift-jenkins"
        DOCKER_CREDENTIALS_ID = "docker-hub"
        GITHUB_REPO = "https://github.com/mfayyadhr/Day30.git"
        OPENSHIFT_PROJECT = "rmuhammadfayyadh-dev"
        OPENSHIFT_SERVER = "https://api.rm1.0a51.p1.openshiftapps.com:6443"
        OPENSHIFT_TOKEN = credentials('open-shift-fayyadh')
        WEBHOOK_URL = "https://e3f70de7b8dc.ngrok-free.app/github-webhook/"
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
                    docker.build("${DOCKER_IMAGE}:${env.DOCKER_TAG}", "-f Dockerfile .")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        echo "Pushing Docker image to Docker Hub"
                        sh """
                            echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                            docker push ${DOCKER_IMAGE}:${env.DOCKER_TAG}
                        """
                    }
                }
            }
        }

        stage('Generate Deployment YAML') {
            steps {
                script {
                    def baseYaml = readFile('base-deployment.yaml')
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
                def route = sh(script: "oc get route fayyadh-java-openshift-jenkins -o jsonpath='{.spec.host}'", returnStdout: true).trim()
                def routeUrl = "http://${route}"
                echo "Deployment successful! Access your app at: ${routeUrl}"
            }
        }

        failure {
            script {
                def payload = """
                {
                  "text": "Jenkins deployment failed for *fayyadh-java-openshift-jenkins* in build #${env.BUILD_NUMBER}",
                    "attachments": 
                    [
                    {"color": "danger",
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