pipeline {
    agent {
        docker {
            image 'mcr.microsoft.com/dotnet/core/sdk:3.1'
        }
    }

    environment {
        MY_REPO = '$GITHUB_TOKEN@github.com:FredSilva92/my-covid-app-be.git';
        CI_REPO = '$GITHUB_TOKEN@github.com:FredSilva92/my-covid-app-be-CI.git';
        CONFIGS = '{
            repositoryConfigs: [
                {
                    name: "core",
                    url: "https://github.com/FredSilva92/my-covid-app-be.git",
                    credentialId: "my-credential"
                }, {
                    name: "core-ci",
                    url: "https://github.com/FredSilva92/my-covid-app-be-CI.git",
                    credentialId: "my-credential"
                }
            ]
        }';
    }

    stages {
        stage('Setup Repositories') {
            steps {
                //sh 'git remote rm ci-repo'
                //sh 'git fetch --all'
                //sh 'git remote add ci-repo $CI_REPO'
                //sh 'git remote update'
                /*sh 'git clone https://github.com/FredSilva92/my-covid-app-be.git'
                sh 'git branch -a'
                sh 'git checkout origin/master'
                sh 'git merge ci-repo/master'*/
                sh 'git checkout -b auto-merges'

                def configs = readJSON text: "$CONFIGS"
                configs.repositoryConfigs.each{ repositoryConfig ->
						withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: repositoryConfig.credentialId, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
	
						}
				}
            }
        }
        stage('build') {
            steps {
                sh 'dotnet build'
            }
        }
    }
}