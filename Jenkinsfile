pipeline {
    agent {
    node {
        label 'demo1'
        
    }
    }
    stages {
        withCredentials([sshUserPrivateKey(credentialsId: "yourkeyid", keyFileVariable: 'keyfile')]) {
        stage('Test') {
            steps {
               
                sh 'df'
            }
        }
    }
}
