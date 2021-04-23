FROM registry.access.redhat.com/rhel7:latest

COPY run.sh /

ENV PROC_LIMIT 1020
ENV DEBUG false

ENTRYPOINT ["./run.sh"]
