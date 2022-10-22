FROM python:3.9-slim AS compile
WORKDIR /app
COPY requirements.txt /app/
COPY app.py /app/
RUN pip install --user -r requirements.txt

FROM python:3.9-slim AS runtime
RUN useradd -ms /bin/bash app
COPY --from=compile /app/ /home/app/
COPY --from=compile /root/.local /home/app/.local
RUN chown -R app:app /home/app/
WORKDIR /home/app
EXPOSE 5000
USER app
ENTRYPOINT ["python3", "app.py"]