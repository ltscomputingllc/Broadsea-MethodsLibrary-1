# syntax=docker/dockerfile:1
FROM rocker/tidyverse:latest
MAINTAINER Lee Evans <evans@ohdsi.org>

ENV DATABASECONNECTOR_JAR_FOLDER="/opt/hades/jdbc_drivers"

RUN apt-get update && apt-get install -y python-dev openjdk-11-jdk liblzma-dev libbz2-dev \
&& R CMD javareconf

RUN --mount=type=secret,id=GITHUB_PAT \
	cp /usr/local/lib/R/etc/Renviron /tmp/Renviron && echo "GITHUB_PAT=$(cat /run/secrets/GITHUB_PAT)" >> /usr/local/lib/R/etc/Renviron

# Install Rserve
RUN install2.r \
	Rserve \
	RSclient \
	openssl \
	httr \
	xml2 \
	remotes \
&& rm -rf /tmp/download_packages/ /tmp/*.rds

# install OHDSI R packages that are not part of HADES
RUN R -e "remotes::install_github(repo = 'OHDSI/Hades', upgrade = 'always')"
RUN R -e "remotes::install_github(repo = 'OHDSI/DataQualityDashboard', upgrade = 'always')"

# install jdbc drivers for database access using OHDSI DatabaseConnector
RUN R <<EOF
library(DatabaseConnector);
downloadJdbcDrivers('postgresql');
downloadJdbcDrivers('redshift');
downloadJdbcDrivers('sql server');
downloadJdbcDrivers('oracle');
downloadJdbcDrivers('spark');
EOF

# install OHDSI Achilles R package
RUN R -e "remotes::install_github(repo = 'OHDSI/Achilles', upgrade = 'always')"

RUN cp /tmp/Renviron /usr/local/lib/R/etc/Renviron

COPY Rserv.conf /etc/Rserv.conf
COPY startRserve.R /usr/local/bin/startRserve.R

EXPOSE 8787
EXPOSE 6311

RUN apt-get update && apt-get install -y supervisor

RUN echo "" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "[supervisord]" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "[program:Rserve]" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "command=/usr/local/bin/startRserve.R" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "[program:RStudio]" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "command=/init" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "stdout_logfile=/var/log/supervisor/%(program_name)s.log" >> /etc/supervisor/conf.d/supervisord.conf \
	&& echo "stderr_logfile=/var/log/supervisor/%(program_name)s.log" >> /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
