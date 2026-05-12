// ============================================================
// Jenkinsfile - Pipeline CI/CD IC GROUP (Windows - PowerShell)
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

        // --------------------------------------------------
        // STAGE 1 : Lire la version depuis releases.txt
        // --------------------------------------------------
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

        // --------------------------------------------------
        // STAGE 2 : BUILD
        // --------------------------------------------------
        stage('Build') {
            steps {
                script {
                    echo "Build de l'image ${IMAGE_NAME}:${env.APP_VERSION}"
                    bat "docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION} ."
                }
            }
        }

        // --------------------------------------------------
        // STAGE 3 : TEST
        // --------------------------------------------------
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

        // --------------------------------------------------
        // STAGE 4 : PACKAGE
        // --------------------------------------------------
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

        // --------------------------------------------------
        // STAGE 5 : DEPLOY via SSH PowerShell (sans sshagent)
        // --------------------------------------------------
        stage('Deploy') {
            steps {
                script {
                    echo "Déploiement via Ansible..."
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'ansible-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )]) {
                        bat """
                            powershell -Command "& ssh -i '%SSH_KEY%' -o StrictHostKeyChecking=no %SSH_USER%@${ANSIBLE_VM} 'cd ~/ansible-role-webapp && ansible-playbook -i ansible/hosts.ini ansible/playbook.yml'"
                        """
                    }
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
