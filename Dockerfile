FROM debian:jessie

RUN apt-get update && apt-get install -y --no-install-recommends \
    gdal-bin \
    python-gdal \
 && rm -rf /var/lib/apt/lists/*

COPY ./data /data
WORKDIR /usr/src/app
COPY ./color_slope.txt ./color_relief.txt ./create_swiss_dem.sh /usr/src/app/

VOLUME /output
CMD ["./create_swiss_dem.sh"]
