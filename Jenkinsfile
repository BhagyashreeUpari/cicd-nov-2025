pipeline {
  agent any

  environment {
    // Set your dockerhub user here or pass as Jenkins credential/env
    DOCKERHUB_USER = "${params.DOCKERHUB_USER ?: '<DOCKERHUB_USER>'}"
    IMAGE_NAME = "${DOCKERHUB_USER}/cicd-demo"
    // credential id in Jenkins for DockerHub (username/password)
    DOCKERHUB_CREDENTIALS = "dockerhub-creds"
    // kubeconfig credentials id (optional file credential)
    KUBECONFIG_CREDENTIALS_ID = "kubeconfig"
    // Helm release name and namespace
    HELM_RELEASE = "cicd-demo"
    HELM_NAMESPACE = "cicd"
  }

  parameters {
    string(name: 'DOCKERHUB_USER', defaultValue: '<DOCKERHUB_USER>', description: 'Docker Hub user to push to')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          python3 -m pip install --user pytest
          python3 -m pytest -q
        '''
      }
    }

    stage('Static/Scan') {
      steps {
        // Run Trivy if installed on agent; tolerate missing scanner
        sh '''
          if command -v trivy >/dev/null 2>&1; then
            echo "Scanning base image for vulnerabilities..."
            trivy image --severity HIGH,CRITICAL --exit-code 1 alpine:3.18 || true
          else
            echo "Trivy not found; skipping vulnerability scan (install trivy on the agent)."
          fi
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // increment build number or use BUILD_NUMBER
          IMAGE_TAG = "${env.BUILD_NUMBER ?: 'local'}"
          env.IMAGE_TAG = IMAGE_TAG
        }
        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
      }
    }

    stage('Docker scan image (trivy)') {
      steps {
        sh '''
          if command -v trivy >/dev/null 2>&1; then
            trivy image --severity HIGH,CRITICAL --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG} || { echo "Vulnerabilities found"; exit 1; }
          else
            echo "Trivy not present - skipping image scan"
          fi
        '''
      }
    }

    stage('Push Image to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
            docker push ${IMAGE_NAME}:latest
            docker logout
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          // Use kubeconfig file credential if provided
          withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG_FILE')]) {
            sh '''
              export KUBECONFIG=$KUBECONFIG_FILE
              kubectl config current-context || true
              kubectl create namespace ${HELM_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
              # Update image in Helm values and run upgrade/install
              helm upgrade --install ${HELM_RELEASE} ./helm-chart \
                --namespace ${HELM_NAMESPACE} \
                --set image.repository=${IMAGE_NAME} \
                --set image.tag=${IMAGE_TAG}
            '''
          }
        }
      }
    }

  } // stages

  post {
    success {
      echo "Pipeline succeeded. Image: ${IMAGE_NAME}:${env.IMAGE_TAG}"
    }
    failure {
      echo "Pipeline failed. Check logs."
    }
  }
}
