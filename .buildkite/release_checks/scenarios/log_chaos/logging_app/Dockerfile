FROM python:3.15-slim

WORKDIR /app

COPY words.txt /app/words.txt
COPY logger.py /app/logger.py

CMD ["python", "-u", "logger.py"]