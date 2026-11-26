// Pipeline CI/CD Jenkins : Git -> tests -> image Docker -> Kubernetes (Minikube)
pipeline {
    // S'execute sur l'agent "vagrant" : la VM, qui dispose de Docker, Minikube et kubectl
    agent { label 'vagrant' }

    // Jenkins verifie GitHub toutes les 2 minutes : chaque git push declenche un build
    triggers { pollSCM('H/2 * * * *') }

    options {
        buildDiscarder(logRotator(numToKeepStr: '15'))
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
    }

    environment {
        IMAGE = 'cc-devops-app'
        TAG   = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Recuperer le code') {
            steps {
                checkout scm
                sh 'git log -1 --format="Commit %h par %an : %s"'
            }
        }

        stage('Construire l image Docker') {
            steps {
                sh 'docker build --build-arg APP_VERSION=build-${TAG} -t ${IMAGE}:${TAG} ./app'
            }
        }

        stage('Tests') {
            steps {
                // Tests unitaires executes DANS l'image qui sera deployee
                sh '''
                    docker run --rm --user root ${IMAGE}:${TAG} \
                      sh -c "pip install -q --no-cache-dir pytest && python -m pytest -q"
                '''
            }
        }

        stage('Charger l image dans Kubernetes') {
            steps {
                sh 'minikube image load ${IMAGE}:${TAG}'
            }
        }

        stage('Deployer sur Kubernetes') {
            steps {
                sh '''
                    sed "s/IMAGE_TAG/${TAG}/" k8s/deployment.yaml | kubectl apply -f -
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/${IMAGE} --timeout=300s
                    kubectl get pods -l app=${IMAGE} -o wide
                '''
            }
        }

        stage('Verifier le deploiement') {
            steps {
                sh '''
                    URL="http://$(minikube ip):30080"
                    curl -fsS "$URL/health"; echo
                    curl -fsS -o /dev/null -w "Page d accueil : HTTP %{http_code}\\n" "$URL/"
                '''
            }
        }
    }

    post {
        success {
            echo "Version build-${TAG} deployee sur Kubernetes"
            // menage : on garde les images recentes seulement
            sh 'docker image prune -f >/dev/null || true'
        }
        failure {
            echo 'Echec : la version precedente reste en ligne (Kubernetes ne bascule que si les pods sont prets)'
        }
    }
}
