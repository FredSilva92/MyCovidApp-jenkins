pipeline {
    agent {
        dockerfile {
            dir '.'
        }
    }

    environment {
        CONFIGS = '{\
            repositoryConfigs: [{\
                name: "core",\
                url: "github.com/FredSilva92/my-covid-app-be.git",\
                oneToOneMapping: "master:master", \
                credentialId: "764d1a6b-9baa-49c2-a484-e57f48fe7b27"},\
                {\
                name: "core-ci",\
                url:"github.com/FredSilva92/my-covid-app-be-CI.git", \
                oneToOneMapping: "master:master",\
                credentialId: "764d1a6b-9baa-49c2-a484-e57f48fe7b27"}], \
            mergeConfigs: [{\
				sourceRepository: "core",\
				targetRepository: "core-ci",\
				oneToOneMapping: "master:master"}\
			]}';
    }

    stages {
        stage('Setup Repositories') {
            steps {
                script {
                    sh "if git show-ref --quiet auto-merges; then git branch -D auto-merges; fi"
                    sh 'git checkout -b auto-merges'

                    def configs = readJSON text: "$CONFIGS"
                    configs.repositoryConfigs.each{ repositoryConfig ->
                        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: repositoryConfig.credentialId, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
                            setupRemote(
								repositoryConfig.name,
								repositoryConfig.url,
								env.GIT_USERNAME,
								env.GIT_PASSWORD)
                        }
                    }
                }

            }
        }
        stage('Perform merge') {
            steps {
                script {
                    def mergeReport = []
					
      			    def configs = readJSON text: "$CONFIGS"
					configs.mergeConfigs.each{ mergeConfig ->
						def oneToOneMapping = 	mergeConfig.oneToOneMapping
                        echo 'One To One Mapping'
                        echo oneToOneMapping

                        def mergesPerformed = performMerges(mergeConfig.sourceRepository,
															mergeConfig.targetRepository, 
															oneToOneMapping.replaceAll("  ", " ").trim())
                        echo 'Merges Performed'
                        //echo mergesPerformed
						if (mergesPerformed != null) {
						    mergeReport.addAll(mergesPerformed)
						}
					}
					
					sh "git checkout auto-merges"
					def jsonOut = readJSON text: groovy.json.JsonOutput.toJson(mergeReport)
				    writeJSON(file: 'mergeReport.json', json: jsonOut)
                }
            }
        }
    }
	post {
		success {
			emailext to: 'pedrofredsilva@gmail.com',
				 subject: 'My successful pipeline',
				 body: 'Hello, the pipeline ran sucessfully'
		}
	}
}

def setupRemote(name = '', url = '', username = '', password = '') {
	boolean remoteExists = (sh(returnStdout: true, script: 'if [[ $(git remote | grep ^' + name + '$) ]]; then echo "true"; else echo "false"; fi').trim() == "true")
	
    echo 'I m here'
	if (!remoteExists) {
		//Create remote
		sh "git remote add " + name + " https://" + url + " "
    
	}


	sh "echo 'https://" + java.net.URLEncoder.encode(username, "UTF-8") + ":" + java.net.URLEncoder.encode(password, "UTF-8") + "@"+ url + "' >> '$WORKSPACE/.git/.git-credentials'"
	sh "git config credential.helper \"store --file='$WORKSPACE/.git/.git-credentials'\""

	// remove all local tags & fetch remote tags
	sh "git tag -l | xargs git tag -d && git fetch -t"
	//Fetch remote
	sh "git fetch -f -P -p " + name
}

def performMerges(sourceRepository = '', targetRepository = '', oneToOneMapping = '') {
	if (oneToOneMapping == null || oneToOneMapping.trim() == "") {
		return
	}
	
	def oneToOneMappingList = oneToOneMapping.trim().split(' ')
	def mergeReport = []	
	
    oneToOneMappingList.each { oneToOneMappingItem ->
		if (oneToOneMappingItem.contains(":")) {
			def oneToOneMappingItemConfig = oneToOneMappingItem.split(':')
			
			mergeReport.add(mergeBranches(	sourceRepository, 
											oneToOneMappingItemConfig[0], 
											targetRepository, 
											oneToOneMappingItemConfig[1]))
		}
    }
    
    return mergeReport
}

def mergeBranches(sourceRepository = '', sourceBranch = '', targetRepository = '', targetBranch = '') {
	echo "##### Merging '$sourceBranch' from '$sourceRepository' into '$targetBranch' from '$targetRepository' #####"

	//Switch to auto-merges branch to enable reset of "local-legacy" and "local-origin"
	sh "git clean -d -fx . && git checkout -f auto-merges"
	
	//Remove "local-legacy" and "local-origin" braches if they exist
	sh "if git show-ref --quiet refs/heads/local-legacy; then git branch -D local-legacy; fi"
	sh "if git show-ref --quiet refs/heads/local-origin; then git branch -D local-origin; fi"
	
	//Checkout $sourceBranch (it should always exist) into "local-legacy"
	sh "git checkout -b local-legacy $sourceRepository/$sourceBranch"
	
	//Hash of commit in source branch
	def headCommitSourceBranch = sh(returnStdout: true, script: "echo \$(git log --pretty=format:'%H' -n 1)").trim()
	
	//Get baseline from source if branch doesn't exist in target
	boolean isNewBranchInTarget = sh(returnStdout: true, script: "git branch -r | egrep '$targetRepository/$targetBranch\$' || echo ''").trim().isEmpty()
	if (isNewBranchInTarget) {
		sh "git checkout -b local-origin $sourceRepository/$sourceBranch"
	}
	else {
		sh "git checkout -b local-origin $targetRepository/$targetBranch"
	}
		
	//Store hash of commit before merge	
	def headCommitBeforeMerge = sh(returnStdout: true, script: "echo \$(git log --pretty=format:'%H' -n 1)").trim()
	def headCommitAuthorBeforeMerge = sh(returnStdout: true, script: "echo \$(git show --format=\"%aN\" \"$headCommitBeforeMerge\" | awk 'NR == 1')").trim()
	
	//Perform merge
	sh "git merge --ff local-legacy --allow-unrelated-histories -m \"Merge branch '$sourceBranch' into '$targetBranch'\" || true"

	//Hash of commit after merge
	def headCommitAfterMerge = sh(returnStdout: true, script: "echo \$(git log --pretty=format:'%H' -n 1)").trim()
	
	//Find common anchestor to identify if there was merge conflicts
	def commonAncestor = sh(returnStdout: true, script: "echo \$(git merge-base local-legacy local-origin)").trim()

	//Prepare report item
	def mergeReportItem = [ 
	    sourceRepository : sourceRepository,
	    sourceBranch : sourceBranch,
	    targetRepository : targetRepository,
	    targetBranch : targetBranch,
	    lastCommitterBeforeMerge : headCommitAuthorBeforeMerge
	]

	if (isNewBranchInTarget || headCommitBeforeMerge != headCommitAfterMerge) {
		sh "git push $targetRepository HEAD:$targetBranch"
		mergeReportItem.result = "SUCCESS"
    }
    else if (commonAncestor != headCommitSourceBranch) {
		sh "git reset --merge"
		mergeReportItem.result = "ERROR"
    }
    else {
	    mergeReportItem.result = "NONE"
    }
	return mergeReportItem
}