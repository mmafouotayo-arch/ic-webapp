// ============================================================
// Jenkinsfile - Pipeline CI/CD IC GROUP
// Stages : Build → Test → Package → Deploy
// ============================================================

pipeline {
    agent any

    environment {
        IMAGE_NAME    = "ic-webapp"
        DOCKERHUB_USER = "mafouo"
        ANSIBLE_VM    = "192.168.109.130"
        ANSIBLE_USER  = "webster123"
    }

    stages {

        // --------------------------------------------------
        // STAGE 1 : Récupérer la version depuis releases.txt
        // --------------------------------------------------
        stage('Read Version') {
            steps {
                script {
                    // Lire la version et les URLs depuis releases.txt
                    env.APP_VERSION  = sh(script: "awk '/version/ {print \$2}' releases.txt", returnStdout: true).trim()
                    env.ODOO_URL     = sh(script: "awk '/ODOO_URL/ {print \$2}' releases.txt", returnStdout: true).trim()
                    env.PGADMIN_URL  = sh(script: "awk '/PGADMIN_URL/ {print \$2}' releases.txt", returnStdout: true).trim()

                    echo "Version    : ${env.APP_VERSION}"
                    echo "ODOO_URL   : ${env.ODOO_URL}"
                    echo "PGADMIN_URL: ${env.PGADMIN_URL}"
                }
            }
        }

        // --------------------------------------------------
        // STAGE 2 : BUILD - Construire l'image Docker
        // --------------------------------------------------
        stage('Build') {
            steps {
                script {
                    echo "Build de l'image ${IMAGE_NAME}:${env.APP_VERSION}"
                    sh """
                        docker build \
                            --build-arg ODOO_URL=${env.ODOO_URL} \
                            --build-arg PGADMIN_URL=${env.PGADMIN_URL} \
                            -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION} .
                    """
                }
            }
        }

        // --------------------------------------------------
        // STAGE 3 : TEST - Vérifier que l'app fonctionne
        // --------------------------------------------------
        stage('Test') {
            steps {
                script {
                    echo "Test du container ic-webapp..."

                    // Lancer le container de test
                    sh """
                        docker run -d \
                            --name test-ic-webapp \
                            -p 8888:8080 \
                            -e ODOO_URL=${env.ODOO_URL} \
                            -e PGADMIN_URL=${env.PGADMIN_URL} \
                            ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}
                        sleep 5
                    """

                    // Tester que l'app répond HTTP 200
                    sh """
                        HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888)
                        if [ "\$HTTP_CODE" != "200" ]; then
                            echo "ERREUR: L'application répond avec le code \$HTTP_CODE"
                            docker rm -f test-ic-webapp
                            exit 1
                        fi
                        echo "Test réussi ! Code HTTP : \$HTTP_CODE"
                    """
                }
            }
            post {
                always {
                    // Toujours supprimer le container de test
                    sh 'docker rm -f test-ic-webapp || true'
                }
            }
        }

        // --------------------------------------------------
        // STAGE 4 : PACKAGE - Pousser l'image sur Docker Hub
        // --------------------------------------------------
        stage('Package') {
            steps {
                script {
                    echo "Push de l'image vers Docker Hub..."
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${env.APP_VERSION}
                        """
                    }
                }
            }
        }

        // --------------------------------------------------
        // STAGE 5 : DEPLOY - Déployer via Ansible
        // --------------------------------------------------
        stage('Deploy') {
            steps {
                script {
                    echo "Déploiement via Ansible..."
                    sshagent(['ansible-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_VM} \
                            "cd ~/ansible-role-webapp && \
                             ansible-playbook -i hosts.ini playbook.yml \
                             -e 'app_version=${env.APP_VERSION}' \
                             -e 'odoo_url=${env.ODOO_URL}' \
                             -e 'pgadmin_url=${env.PGADMIN_URL}'"
                        """
                    }
                }
            }
        }
    }

    // --------------------------------------------------
    // NOTIFICATIONS - Résultat du pipeline
    // --------------------------------------------------
    post {
        success {
            echo "✅ Pipeline terminé avec succès ! Version ${env.APP_VERSION} déployée."
        }
        failure {
            echo "❌ Pipeline échoué ! Vérifiez les logs."
        }
        always {
            // Nettoyage des images locales anciennes
            sh "docker image prune -f || true"
        }
    }
}
