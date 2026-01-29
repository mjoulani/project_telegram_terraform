FROM python:3.14.2-alpine3.23
WORKDIR /usr/src/app
RUN pip install --upgrade pip
COPY app.py .
COPY bot.py .
COPY requirements.txt .
RUN pip install -r requirements.txt

EXPOSE 8443
CMD ["python","app.py"]