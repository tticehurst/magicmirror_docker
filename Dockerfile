FROM node:22-alpine AS base
LABEL name="MagicMirror" \
      version="2.0" \
      description="create image with MagicMirror and all our modules keeping ssh private key out of the final image"

RUN set -e; \
    apk update; \
    apk add --no-cache git openssh-client openssh-server; \
    rm -rf /var/cache/apk/*






# build modules
FROM base as builder
ARG SSH_PRIVATE_KEY
RUN mkdir -p /root/.ssh && \
    echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa

RUN set -e; \
    touch /root/.ssh/known_hosts\
    && ssh-keyscan github.com >> /root/.ssh/known_hosts

ENV NODE_ENV production
ARG branch=master
WORKDIR /opt/magic_mirror

RUN git clone --depth 1 -b ${branch} https://github.com/MichMich/MagicMirror.git .
RUN npm install --unsafe-perm
RUN set -e; \
    modules=" \
    https://github.com/tticehurst/MMMessages.git\
    https://github.com/tticehurst/MMM-SimplePowerGeneration.git\
    https://github.com/tticehurst/MMM-NewClock.git\
    https://github.com/tticehurst/MMM-TrainTimesRTT.git\
    https://github.com/tticehurst/MMM-EasyPix.git\
    https://github.com/tticehurst/MMM-CalendarDisplayMonthOverview.git\
    https://github.com/tticehurst/MMM-CalendarDisplay.git\
    https://github.com/tticehurst/TomWeather.git\
    https://github.com/cowboysdude/MMM-Xmas.git\
    https://github.com/MichMich/MMM-Snow.git\
    https://github.com/MMM-CalendarExt2/MMM-CalendarExtMinimonth.git\
    https://github.com/cbrooker/MMM-Todoist.git\
    https://github.com/timdows/MMM-JsonTable.git\
    https://github.com/lavolp3/MMM-MyCommute.git\
    https://github.com/ianperrin/MMM-ModuleScheduler.git\
    "; \
    for module in $modules; do \
    module_name=$(basename $module .git); \
    git clone $module modules/$module_name; \
    if [ -d "modules/$module_name" ]; then \
    find modules/$module_name -type f -name "package.json" -exec sh -c 'cd $(dirname "{}") && npm install --unsafe-perm && npm audit fix ' \;; \
    fi; \
    done
RUN rm -rf /root/.ssh






# build final image, copying over built modules
FROM base
WORKDIR /opt/magic_mirror
COPY --from=builder /opt/magic_mirror .

EXPOSE 8080
EXPOSE 8081

CMD ["node", "serveronly"]
