locals {
  auto_stop_idle_script = base64encode(<<EOF
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

#!/bin/bash
set -eux
ASI_VERSION=0.3.0

# User variables [update as needed]
IDLE_TIME_IN_SECONDS=120  # in seconds, change this to desired idleness time before app shuts down

# System variables [do not change if not needed]
CONDA_HOME=/opt/conda/bin
LOG_FILE=/var/log/apps/app_container.log # Writing to app_container.log delivers logs to CW logs.
SOLUTION_DIR=/var/tmp/auto-stop-idle # Do not use /home/sagemaker-user
PYTHON_PACKAGE=sagemaker_code_editor_auto_shut_down-$ASI_VERSION.tar.gz
PYTHON_SCRIPT_PATH=$SOLUTION_DIR/sagemaker_code_editor_auto_shut_down/auto_stop_idle.py

# Installing cron
sudo apt-get update -y
sudo sh -c 'printf "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d'
sudo apt-get install -y cron

# Creating solution directory.
sudo mkdir -p $SOLUTION_DIR

# Downloading autostop idle Python package.
echo "Downloading autostop idle Python package..."
curl -LO --output-dir /var/tmp/ https://github.com/aws-samples/sagemaker-studio-apps-lifecycle-config-examples/releases/download/v$ASI_VERSION/$PYTHON_PACKAGE
sudo $CONDA_HOME/pip install -U -t $SOLUTION_DIR /var/tmp/$PYTHON_PACKAGE

# Touch file to ensure idleness timer is reset to 0
echo "Touching file to reset idleness timer"
touch /opt/amazon/sagemaker/sagemaker-code-editor-server-data/data/User/History/startup_timestamp

# Setting container credential URI variable to /etc/environment to make it available to cron
sudo /bin/bash -c "echo 'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI' >> /etc/environment"

# Add script to crontab for root.
echo "Adding autostop idle Python script to crontab..."
echo "*/2 * * * * /bin/bash -ic '$CONDA_HOME/python $PYTHON_SCRIPT_PATH --time $IDLE_TIME_IN_SECONDS --region $AWS_DEFAULT_REGION >> $LOG_FILE'" | sudo crontab -
EOF
  )
}



resource "aws_sagemaker_domain" "poc_domain" {
  domain_name = "poc-domain"
  auth_mode   = "IAM"
  vpc_id      = aws_default_vpc.poc_vpc.id
  subnet_ids  = [aws_default_subnet.poc_subnet.id]
  default_user_settings {
    execution_role = aws_iam_role.poc_role.arn
     studio_web_portal  = "ENABLED"
     default_landing_uri = "studio::"

    jupyter_server_app_settings {
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.auto_stop_idle_config.arn]

      default_resource_spec {
        instance_type       = "system"
        sagemaker_image_arn = "arn:aws:sagemaker:ca-central-1:310906938811:image/jupyter-server-3"
      }
    }
  }
}


resource "aws_sagemaker_studio_lifecycle_config" "auto_stop_idle_config" {
  studio_lifecycle_config_name     = "auto-stop-idle-config"
  studio_lifecycle_config_app_type = "JupyterLab"
  studio_lifecycle_config_content  = local.auto_stop_idle_script
}

resource "aws_sagemaker_user_profile" "poc_user_profile" {
	domain_id = aws_sagemaker_domain.poc_domain.id
	user_profile_name = "poc-user-profile"
	user_settings {
		execution_role = aws_iam_role.poc_role.arn
	}
}
