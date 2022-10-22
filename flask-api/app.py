from flask import Flask, request, jsonify
from datetime import datetime
import socket
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware


app = Flask(__name__)

health_status = True

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Application info', version='1.0.3')

dispatcher = DispatcherMiddleware(app.wsgi_app, {"/metrics": make_wsgi_app()})


@app.route('/')
# get API home page
def home():
    return "This is an API to show timestamp and hostname.Request to /timestamp or /hostname"


@app.route('/timestamp/')
# get timestamp page
def timestamp():
    current_time = datetime.now()
    str_date_time = current_time.strftime("%d-%m-%Y, %H:%M:%S")
    return "DateTime: {}" .format(str_date_time)

@app.route("/hostname/")
# get hostname page
def hostname():
    hostname = socket.gethostname()
    remote_adrr = request.remote_addr
    return "This is an example wsgi app served from {} to {}".format(socket.gethostname(), request.remote_addr)

@app.route('/health')
def health():
    if health_status:
        resp = jsonify(health="healthy")
        resp.status_code = 200
    else:
        resp = jsonify(health="unhealthy")
        resp.status_code = 500

    return resp

if __name__ == "__main__":

    app.run(host='0.0.0.0', threaded=True)