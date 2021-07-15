#!/bin/bash
curl --proto "https" -o "/tmp/ecs-anywhere-install.sh" "https://amazon-ecs-agent.s3.amazonaws.com/ecs-anywhere-install-latest.sh"
bash /tmp/ecs-anywhere-install.sh --region ${region} --cluster ${cluster} --activation-id ${activation_id} --activation-code ${activation_code}