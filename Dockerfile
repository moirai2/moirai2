FROM python:3.7
RUN apt-get update \
&& apt-get install -y --no-install-recommends \
perl \
libwww-perl
COPY flask/requirements.txt .
RUN pip install -r requirements.txt \
&& rm requirements.txt
COPY ./moirai2.pl /usr/local/bin/
COPY ./rdf.pl /usr/local/bin/
COPY ./openstack.pl /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.pl
WORKDIR /code
CMD ["python", "app.py"]
