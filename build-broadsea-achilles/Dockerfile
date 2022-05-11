# syntax=docker/dockerfile:1
#FROM ohdsi/broadsea-hades:latest
FROM levansltscomputingllc/broadsea-hades:latest
MAINTAINER Lee Evans <evans@ohdsi.org>

RUN --mount=type=secret,id=GITHUB_PAT \
	cp /usr/local/lib/R/etc/Renviron /tmp/Renviron && echo "GITHUB_PAT=$(cat /run/secrets/GITHUB_PAT)" >> /usr/local/lib/R/etc/Renviron

# install OHDSI Achilles R package into ohdsi/broadsea-hades:latest Docker container
RUN R -e "remotes::install_github(repo = 'OHDSI/Achilles', upgrade = 'always')"

EXPOSE 8787
EXPOSE 6311

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
