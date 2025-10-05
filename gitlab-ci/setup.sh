#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting GitLab setup script...${NC}"

# Check if GitLab is already running
if curl -s --connect-timeout 5 http://localhost/users/sign_in > /dev/null; then
  echo -e "${GREEN}GitLab is running!${NC}"
else
  echo -e "${YELLOW}GitLab is not running, starting services...${NC}"
  # Start GitLab and GitLab Runner using docker compose
  docker compose up -d

  # Waiting for GitLab to start
  echo -e "${YELLOW}Waiting for GitLab to start...${NC}"

  # Wait for GitLab to be responsive
  until curl -s http://localhost/users/sign_in > /dev/null; do
    echo "GitLab is not ready yet, waiting 30 seconds..."
    sleep 30
  done

  echo -e "${GREEN}GitLab is up and running!${NC}"
fi

# Retrieving GitLab root token
echo -e "${YELLOW}Retrieving GitLab root token...${NC}"

# Get the root API token with proper expiration date and token setting
ROOT_TOKEN=$(docker exec -it gitlab gitlab-rails runner "
  user = User.find_by_username('root')
  token_string = SecureRandom.hex(20)
  expires_at = Date.today + 7
  token = user.personal_access_tokens.create(
    name: 'Root API Token',
    scopes: [:api],
    expires_at: expires_at
  )
  token.set_token(token_string)
  token.save!
  puts token_string
")

# Clean up the token (remove any leading/trailing whitespace)
ROOT_TOKEN=$(echo $ROOT_TOKEN | tr -d '\r' | tr -d '\n')

echo -e "${GREEN}Root token retrieved successfully!${NC}"
echo $ROOT_TOKEN

# Creating a runner using the API
echo -e "${YELLOW}Creating a new runner via API...${NC}"

RUNNER_RESPONSE=$(curl -s --request POST \
  --header "PRIVATE-TOKEN: $ROOT_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{
    "description": "docker-runner",
    "runner_type": "instance_type",
    "tag_list": "docker,build",
    "run_untagged": true,
    "locked": false,
    "active": true,
    "paused": false
  }' \
  "http://localhost/api/v4/user/runners")

# Extract the token from the response
echo $RUNNER_RESPONSE
RUNNER_TOKEN=$(echo $RUNNER_RESPONSE | jq -r '.token')

echo -e "${GREEN}Runner created via API, token obtained: ${RUNNER_TOKEN}${NC}"

# Registering GitLab Runner with the new token
echo -e "${YELLOW}Registering GitLab runners...${NC}"

docker exec -it gitlab-runner-1 gitlab-runner register \
  --non-interactive \
  --url "http://gitlab" \
  --token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image "docker:latest" \
  --description "docker-runner-1" \
  --docker-privileged="true" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-network-mode "gitlab-network"

docker exec -it gitlab-runner-2 gitlab-runner register \
  --non-interactive \
  --url "http://gitlab" \
  --token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image "docker:latest" \
  --description "docker-runner-2" \
  --docker-privileged="true" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-network-mode "gitlab-network"

echo -e "${GREEN}GitLab runners registered successfully!${NC}"

# Creating a sample project
echo -e "${YELLOW}Creating a sample project...${NC}"

curl --silent --request POST --header "PRIVATE-TOKEN: $ROOT_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"name": "sample-project", "description": "A sample project for CI/CD", "visibility": "internal"}' \
  "http://localhost/api/v4/projects"

echo -e "${GREEN}Sample project created successfully!${NC}"

# Retrieve the root password from the GitLab container
echo -e "${YELLOW}Retrieving root password...${NC}"
ROOT_PASSWORD=$(docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $2}')

# Check if the GitLab hostname is resolved
# TODO: check for errors ("./setup.sh: line 121: getent: command not found")
if ! getent hosts gitlab > /dev/null; then
  echo -e "${YELLOW}GitLab hostname not resolved. Adding entry to /etc/hosts...${NC}"
  echo -e "\n\n# [devops-training] Entry to resolve the local GitLab instance\n127.0.0.1 gitlab" | sudo tee -a /etc/hosts > /dev/null
  echo -e "${GREEN}Entry added to /etc/hosts successfully!${NC}"
else
  echo -e "${GREEN}GitLab hostname is already resolved.${NC}"
fi

echo -e "${GREEN}GitLab setup completed successfully!${NC}"
echo -e "${YELLOW}You can access GitLab at http://gitlab${NC}"
echo -e "${YELLOW}Login with username: root and password: ${ROOT_PASSWORD}${NC}"

exit 0
