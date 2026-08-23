docker build --no-cache --build-arg SSH_PRIVATE_KEY="$(cat ./github-keys/private-key)" -t magic .
