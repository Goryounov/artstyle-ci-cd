FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80


pipeline {
    agent { label 'goryunov_node' }
    environment {
        DOCKER_HUB_REPO = "goryunoff/artstyle"  // Один репозиторий для обоих образов
        DOCKERFILE_REPO = "https://github.com/Goryounov/artstyle-ci-cd.git"
        SERVER_IP = "192.168.199.121"  // IP-адрес сервера, куда будем деплоить
        SSH_CREDENTIALS = "9eb313c9-4737-47a4-9097-4639770c5192"  // SSH credentials в Jenkins
        SERVER_USER = "ubuntu"  // Пользователь для SSH доступа
    }
    stages {
        stage('Clone Repository') {
            steps {
                script {
                    // Клонирование репозитория с общим Dockerfile
                    dir('artstyle-ci-cd') {
                        git branch: 'master', url: DOCKERFILE_REPO
                    }
                }
            }
        }
        stage('Build Images') {
            steps {
                script {
                    // Сборка одного и того же Dockerfile для artstyle-client
                    dir('artstyle-ci-cd') {
                        sh 'sudo docker build -t ${DOCKER_HUB_REPO}-client:latest .'
                    }

                    // Сборка одного и того же Dockerfile для artstyle-server
                    dir('artstyle-ci-cd') {
                        sh 'sudo docker build -t ${DOCKER_HUB_REPO}-server:latest .'
                    }
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: '68defd9f-3613-4b26-ac22-7c2de1824bda', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        // Авторизация в Docker Hub
                        sh 'echo $DOCKER_PASSWORD | sudo docker login -u $DOCKER_USERNAME --password-stdin'

                        // Загрузка образов в один репозиторий на Docker Hub
                        sh '''
                        sudo docker push ${DOCKER_HUB_REPO}-client:latest
                        sudo docker push ${DOCKER_HUB_REPO}-server:latest
                        '''

                        // Выход из Docker Hub
                        sh 'docker logout'
                    }
                }
            }
        }
        stage('Deploy to Server') {
            steps {
                script {
                    // Подключение к серверу через SSH и деплой контейнеров
                    sshagent(credentials: [SSH_CREDENTIALS]) {
                        sh """
                        ssh -t -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
                            # Пуллинг Docker образов
                            sudo docker pull ${DOCKER_HUB_REPO}-client:latest
                            sudo docker pull ${DOCKER_HUB_REPO}-server:latest

                            # Остановка и удаление старых контейнеров (если они есть)
                            sudo docker stop artstyle-client || true
                            sudo docker stop artstyle-server || true
                            sudo docker rm artstyle-client || true
                            sudo docker rm artstyle-server || true

                            # Запуск новых контейнеров
                            sudo docker run -d --name artstyle-client -p 3000:3000 ${DOCKER_HUB_REPO}-client:latest
                            sudo docker run -d --name artstyle-server -p 8000:8000 ${DOCKER_HUB_REPO}-server:latest
                        EOF
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            // Очистка образов на Jenkins агенте
            sh '''
            docker rmi -f ${DOCKER_HUB_REPO}/artstyle-client:latest ${DOCKER_HUB_REPO}/artstyle-server:latest || true
            '''
        }
    }
}