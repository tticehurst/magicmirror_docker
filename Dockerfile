FROM node:lts

RUN set -e; \
    apt update; \
    apt install -y vim gettext openssh-server; \
    rm -rf /var/lib/apt/lists/*


ARG branch=master

COPY ./github-keys/* /root/.ssh/

RUN set -e; \
    echo "# SSH Config for GitHub Accounts" > /root/.ssh/config \
    && for keyfile in /root/.ssh/*; do \
    [ -f "$keyfile" ] && [ "$(basename "$keyfile")" != "config" ] && \
    keyname=$(basename "$keyfile") && \
    echo "Host github.com" >> /root/.ssh/config \
    && echo "  HostName github.com" >> /root/.ssh/config \
    && echo "  User git" >> /root/.ssh/config \
    && echo "  IdentityFile /root/.ssh/$keyname" >> /root/.ssh/config \
    && echo "  PreferredAuthentications publickey" >> /root/.ssh/config;\
    done

RUN set -e; \
    touch /root/.ssh/known_hosts\
    && ssh-keyscan github.com >> /root/.ssh/known_hosts


RUN set -e;\
    chmod 600 /root/.ssh/*

ENV NODE_ENV production
WORKDIR /opt/magic_mirror

RUN git clone --depth 1 -b ${branch} https://github.com/MichMich/MagicMirror.git .

RUN npm install --unsafe-perm 

COPY modules.txt /tmp/modules.txt
RUN set -e; \
    cat /tmp/modules.txt | while read module; do\
        module_name=$(basename $module .git); \
        git clone $module modules/$module_name;\
        if [ -d "modules/$module_name" ]; then \
            find modules/$module_name -type f -name "package.json" -exec sh -c 'cd $(dirname "{}") && npm install --unsafe-perm && npm audit fix ' \;; \
        fi; \
    done

RUN rm -rf /root/.ssh

EXPOSE 8080
EXPOSE 8081

CMD ["node", "serveronly"]
