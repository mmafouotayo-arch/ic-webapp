// ============================================================
// Jenkinsfile - Pipeline CI/CD IC GROUP (Windows)
// ============================================================

pipeline {
    agent any

    environment {
        IMAGE_NAME     = "ic-webapp"
        DOCKERHUB_USER = "mafouo"
        ANSIBLE_VM     = "192.168.109.130"
        ANSIBLE_USER   = "webster123"
    }

    stages {

        stage('Read Version') {
            steps {
                script {
                    def content = readFile('releases.txt')
                    def lines = content.readLines()
                    lines.each { line ->
                        if (line.startsWith('version:')) {
                            env.APP_VERSION = line.split(':')[1].trim()
                        }
                        if (line.startsWith('ODOO_URL:')) {
                            env.ODOO_URL = line.split(':')[1].trim() + ':' + line.split(':')[2].trim()
                        }
                        if (line.startsWith('PGADMIN_URL:')) {
                            env.PGADMIN_URL = line.split(':')[1].trim() + ':' + line.split(':')[2].trim()
                        }
                    }
                    echo "Version     : ${env.APP_VERSION}"
                    echo "ODOO_URL    : ${env.ODOO_URL}"
                    echo "PGADMIN_URL : ${env.PGADMIN_URL}"
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    echo "Build de l'image ${IMAGE_NAME}:${env.APP_VERSION}"
                    bat "docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION} ."
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    echo "Lancement du container de test..."
                    bat "docker run -d --name test-ic-webapp -p 8888:8080 -e ODOO_URL=${env.ODOO_URL} -e PGADMIN_URL=${env.PGADMIN_URL} ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}"
                    sleep(5)
                    bat """powershell -Command "\$r = Invoke-WebRequest -Uri http://localhost:8888 -UseBasicParsing; if (\$r.StatusCode -eq 200) { Write-Host 'Test OK: ' \$r.StatusCode } else { exit 1 }" """
                }
            }
            post {
                always {
                    bat 'docker rm -f test-ic-webapp || exit 0'
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    echo "Push vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        bat "docker login -u %DOCKER_USER% -p %DOCKER_PASS%"
                        bat "docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Déploiement via Ansible sur ${ANSIBLE_VM}..."
                    // Copier la clé, fixer les permissions et se connecter
                    bat """
                        copy C:\\ProgramData\\Jenkins\\.jenkins\\.ssh\\id_rsa %TEMP%\\jenkins_key.pem
                        icacls %TEMP%\\jenkins_key.pem /inheritance:r
                        icacls %TEMP%\\jenkins_key.pem /grant:r "%USERNAME%:(R)"
                        ssh -i %TEMP%\\jenkins_key.pem -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_VM} "cd ~/ansible-role-webapp && ansible-playbook -i ansible/hosts.ini ansible/playbook.yml"
                        del %TEMP%\\jenkins_key.pem
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé ! Version ${env.APP_VERSION} déployée."
        }
        failure {
            echo "❌ Pipeline échoué ! Vérifiez les logs."
        }
        always {
            bat 'docker image prune -f || exit 0'
        }
    }
}
