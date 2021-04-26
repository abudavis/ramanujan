FROM registry.access.redhat.com/rhel7:latest

COPY run.sh /

ENV PROC_LIMIT 4000 
ENV DEBUG false

ENTRYPOINT ["./run.sh"]
