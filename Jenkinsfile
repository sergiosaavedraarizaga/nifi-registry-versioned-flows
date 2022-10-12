pipeline {
    agent { node { label 'demo1' } }
    environment {
    current_branch = "${env.BRANCH_NAME}"
    }
    stages {
        stage('Check branch') {
          when {
            
              anyOf {
                branch "main"
                branch "feature/*"
                branch "release/*"
                branch "bugfix/*"
              }
            
          }
          steps {
            error "Wrong branch name"
          }
        }
        
        stage('Test') {
            steps {
               
                sh 'df'
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'qa'){
                      sh '''
                      #!/usr/bin/bash
                      flow_name=$(eval cat ./flow.json | jq '.[].flow_name')
                      flow_version=$(cat ./flow.json | jq '.[].flow_version')
                      /home/ubuntu/cicd.sh $flow_name $flow_version qa
                      '''
                    } else if (env.BRANCH_NAME == 'main'){
                      sh '''
                      #!/usr/bin/bash
                      flow_name=$(eval cat ./flow.json | jq '.[].flow_name')
                      flow_version=$(cat ./flow.json | jq '.[].flow_version')
                      /home/ubuntu/cicd.sh $flow_name $flow_version prod
                      ''' 
                      }
                    }  
               }
           }    
       }
}
