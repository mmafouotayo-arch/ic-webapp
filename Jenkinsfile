// ============================================================
// Jenkinsfile - Pipeline CI/CD IC GROUP (Compatible Windows)
// Stages : Build → Test → Package → Deploy
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
                    // Compatible Windows - lire releases.txt avec PowerShell
                    env.APP_VERSION = bat(
                        script: '@for /f "tokens=2" %a in (\'findstr "version" releases.txt\') do @echo %a',
                        returnStdout: true
                    ).trim()

                    env.ODOO_URL = bat(
                        script: '@for /f "tokens=2" %a in (\'findstr "ODOO_URL" releases.txt\') do @echo %a',
                        returnStdout: true
                    ).trim()

                    env.PGADMIN_URL = bat(
                        script: '@for /f "tokens=2" %a in (\'findstr "PGADMIN_URL" releases.txt\') do @echo %a',
                        returnStdout: true
                    ).trim()

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
                    bat """
                        docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION} .
                    """
                }
            }
        }

        // --------------------------------------------------
        // STAGE 3 : TEST
        // --------------------------------------------------
        stage('Test') {
            steps {
                script {
                    echo "Test du container ic-webapp..."
                    bat """
                        docker run -d ^
                            --name test-ic-webapp ^
                            -p 8888:8080 ^
                            -e ODOO_URL=${env.ODOO_URL} ^
                            -e PGADMIN_URL=${env.PGADMIN_URL} ^
                            ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}
                    """
                    sleep(5)

                    // Test HTTP avec PowerShell
                    bat """
                        powershell -Command "try { \$r = Invoke-WebRequest -Uri http://localhost:8888 -UseBasicParsing; if (\$r.StatusCode -eq 200) { Write-Host 'Test reussi ! Code: ' \$r.StatusCode } else { Write-Host 'Test echoue ! Code: ' \$r.StatusCode; exit 1 } } catch { Write-Host 'Erreur connexion'; exit 1 }"
                    """
                }
            }
            post {
                always {
                    bat 'docker rm -f test-ic-webapp || exit 0'
                }
            }
        }

        // --------------------------------------------------
        // STAGE 4 : PACKAGE - Push Docker Hub
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
                        bat """
                            docker login -u %DOCKER_USER% -p %DOCKER_PASS%
                            docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}
                        """
                    }
                }
            }
        }

        // --------------------------------------------------
        // STAGE 5 : DEPLOY - Via Ansible sur la VM
        // --------------------------------------------------
        stage('Deploy') {
            steps {
                script {
                    echo "Déploiement via Ansible..."
                    sshagent(['ansible-ssh-key']) {
                        bat """
                            ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_VM} "cd ~/ansible-role-webapp && ansible-playbook -i ansible/hosts.ini ansible/playbook.yml"
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline terminé avec succès ! Version ${env.APP_VERSION} déployée."
        }
        failure {
            echo "❌ Pipeline échoué ! Vérifiez les logs."
        }
        always {
            bat 'docker image prune -f || exit 0'
        }
    }
}
