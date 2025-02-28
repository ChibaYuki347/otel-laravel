FROM otel/opentelemetry-collector-contrib:0.114.0

# Set Environment Variables
ENV APPLICATIONINSIGHTS_CONNECTION_STRING=your-connection_string_here

COPY otel-collector-config.yaml /etc/configs/otel-collector-config.yaml

ENTRYPOINT ["/otelcol-contrib"]

CMD ["--config=/etc/configs/otel-collector-config.yaml"]
EXPOSE 4317 55679 4318