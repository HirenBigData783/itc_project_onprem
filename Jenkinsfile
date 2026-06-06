pipeline {
    agent any

    parameters {
        password(name: 'REMOTE_PASSWORD', defaultValue: '', description: 'Remote SSH password for Cloudera')
        string(name: 'SQOOP_USER', defaultValue: 'consultant', description: 'PostgreSQL username for Sqoop')
        password(name: 'SQOOP_PASS', defaultValue: 'WelcomeItc@2026', description: 'PostgreSQL password for Sqoop')
    }

    environment {
        REMOTE_HOST = '13.41.167.97'
        REMOTE_USER = 'consultant'
        REMOTE_PASSWORD = 'WelcomeItc@2026'
        PROJECT_DIR = '/home/consultant/hiren/TFL_Project_1'
        HDFS_DIR = '/tmp/hiren/tfl_proj/tfl_data_1'
        SSH_OPTS = '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Validate Parameters') {
            steps {
                sh '''
                    if [ -z "$REMOTE_PASSWORD" ]; then
                        echo "REMOTE_PASSWORD is required. Run the job with Build with Parameters and enter the Cloudera SSH password."
                        exit 1
                    fi

                    if [ -z "$SQOOP_USER" ]; then
                        echo "SQOOP_USER is required."
                        exit 1
                    fi

                    if [ -z "$SQOOP_PASS" ]; then
                        echo "SQOOP_PASS is required. Run the job with Build with Parameters and enter the PostgreSQL password."
                        exit 1
                    fi
                '''
            }
        }

        stage('Check Jenkins Agent Tools') {
            steps {
                sh '''
                    command -v sshpass
                    command -v ssh
                    command -v scp
                '''
            }
        }
        

        // stage('Prepare Remote Directory') {
        //     steps {
        //         sh '''
        //             export SSHPASS="$REMOTE_PASSWORD"
        //             sshpass -e ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
        //                 "mkdir -p '$PROJECT_DIR/src/raw_layer/'"
        //         '''
        //     }
        // }

        stage('Prepare Remote Directory') {
            steps {
                echo '========================================='
                echo 'Stage 2: Create Directories on Cloudera'
                echo '========================================='
                sh '''
                    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                        ${REMOTE_USER}@${REMOTE_HOST} \
                        "mkdir -p ${PROJECT_DIR}/src/raw_layer"
                        grep -v "ITC Big Data Lab" | grep -v "Commands:" | grep -v "HDFS home:" | grep -v "━" || true

                    echo "Directories created"
                '''
            }
        }

        stage('Copy Scripts to Cloudera') {
            steps {
                sh '''
                    export SSHPASS="$REMOTE_PASSWORD"
                    sshpass -e scp $SSH_OPTS \
                        src/sqoop/pgs_to_hadoop.sh \
                        src/sqoop/create_hive_tables.hql \
                        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/src/raw_layer/"
                '''
            }
        }

        stage('Set Permissions') {
            steps {
                sh '''
                    export SSHPASS="$REMOTE_PASSWORD"
                    sshpass -e ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
                        "chmod +x '$PROJECT_DIR/src/raw_layer/pgs_to_hadoop.sh'"
                '''
            }
        }

        stage('Prepare Remote Staging') {
            steps {
                sh '''
                    export SSHPASS="$REMOTE_PASSWORD"
                    sshpass -e ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
                        "mkdir -p /tmp/hadoop/mapred/staging"
                '''
            }
        }

        stage('Clean HDFS Target') {
            steps {
                sh '''
                    export SSHPASS="$REMOTE_PASSWORD"
                    sshpass -e ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
                        "hdfs dfs -rm -r -f -skipTrash '$HDFS_DIR' || true"
                '''
            }
        }

        stage('Sqoop Import and Hive Tables') {
            steps {
                sh '''
                    export SSHPASS="$REMOTE_PASSWORD"
                    sshpass -e ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
                        "SQOOP_USER='$SQOOP_USER' SQOOP_PASS='$SQOOP_PASS' bash '$PROJECT_DIR/sqoop/pgs_to_hadoop.sh'"
                '''
            }
        }

        stage('Verify HDFS Data') {
            steps {
                sh '''
                    export SSHPASS="$REMOTE_PASSWORD"
                    sshpass -e ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
                        "hdfs dfs -ls '$HDFS_DIR'"
                '''
            }
        }
    }

    post {
        success {
            echo 'TFL PIPELINE COMPLETED SUCCESSFULLY'
            echo "Cloudera: ${REMOTE_HOST}:${PROJECT_DIR}"
            echo "HDFS: ${HDFS_DIR}"
        }
        failure {
            echo 'TFL PIPELINE FAILED - check logs above'
        }
        always {
            echo 'Pipeline execution completed'
        }
    }
}
