def NAME
def version

pipeline {
    agent { label 'jenkins-4'}
    options {
        buildDiscarder(
            logRotator(
                numToKeepStr: '5', 
                artifactNumToKeepStr: '5'
            )
        )
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }

    stages {
        // Checkout code with tags. The regular scm call does a flat checkout
        // and we need the tags to set the version
        stage("Checkout") {
            steps {
                gitCheckout()
            }
        }

        // set version with the following scheme
        //   tags:   version = <tag>
        //   PR:     version = <latest tag>.<PR number>
        //   branch: version = <latest tag>-<branch name>
        stage ('Getter information') {
            steps {
                prepareInfo()
            }
        }

        stage('Run Tests') {
            agent {
                docker { 
                    image 'golang:1.16-bullseye'
                    reuseNode true
                }
            }
            steps {
                sh 'go test'
            }
        }

        stage('Build go package') {
            agent {
                docker { 
                    image 'golang:1.16-bullseye'
                    reuseNode true
                }
            }
            steps {
                sh "go build -o ./build/${NAME} -ldflags \"-s -X cmd.AppVersion=${version}\""
            }
        }

        stage ('Build deb package') {
            steps {
                script {
                    sh "version=${version} nfpm pkg --target ${NAME}_${version}-amd64.deb"
                    sh "dpkg-deb -I ${NAME}_${version}-amd64.deb"
                    sh "dpkg -c ${NAME}_${version}-amd64.deb"
                }
            }
        }

        stage ('Publish deb package') {
            when { 
                buildingTag()
             }
            steps {
                sshagent (credentials: ['jenkins-ssh']) {
                    script {
                        sh "scp -o StrictHostKeyChecking=no ${NAME}_${version}-amd64.deb root@aptly.productsup.com:/tmp/"
                        sh "ssh -o StrictHostKeyChecking=no root@aptly.productsup.com \"aptly repo add stable /tmp/${NAME}_${version}-amd64.deb && \
                           aptly publish update -passphrase-file='/root/.aptly/passphrase' -batch stable s3:aptly-productsup:debian && rm /tmp/${NAME}_${version}-amd64.deb\""
                    }
                }
            }
        }
    }

    post ('Cleanup') {
        cleanup {
            cleanWs deleteDirs: true
        }
    }
}

