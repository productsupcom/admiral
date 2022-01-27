env.name                       = "admiral"
env.description                = "admiral"
env.maintainer                 = "Operations Team <ops@productsup.com>"
env.homepage                   = "https://github.com/productsupcom/admiral"

env.version
env.branch
env.gitCommitHash
env.gitCommitAuthor
env.gitCommitMessage
env.package_file_name
env.branch_location

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
                sh "go build -o ./build/${env.name} -ldflags \"-s -X cmd.AppVersion=${env.version}\""
            }
        }

        stage ('Build deb package') {
            when { 
                buildingTag()
            }
            steps {
                script {
                    def package_internal_name = "${env.name}"

                    setPackageName(customName: "${env.name}-${env.version}")
                    // build
                    buildDebPackageBin(
                        package_internal_name: "${package_internal_name}",
                        package_file_name: "${env.package_file_name}",
                        version: "${env.version}",
                        description: "${env.description}",
                        homepage: "${env.homepage}",
                        maintainer: "${env.maintainer}",
                    )
                }
            }
        }

        stage ('Publish deb package') {
            when {
                buildingTag()
            }
            steps {
                publishDebPackage(package_name: "${env.package_file_name}_all.deb")
            }
        }
    }

    post ('Cleanup') {
        cleanup {
            cleanWs deleteDirs: true
        }
    }
}

