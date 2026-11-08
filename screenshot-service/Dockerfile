FROM mcr.microsoft.com/playwright/python:v1.49.0-noble
WORKDIR /app
RUN pip install --no-cache-dir flask playwright && playwright install --with-deps chromium
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]