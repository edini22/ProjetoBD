import flask, psycopg2
import logging

app = flask.Flask(__name__)

StatusCodes = {
    'success': 200,
    'api_error': 400,
    'internal_error': 500
}

# Acesso a DataBase
def db_connection():
    db = psycopg2.connect(
        user = "aulaspl",
        password = "aulaspl",
        host = "127.0.0.1", 
        port = "5432",
        database = "projetobd"
    )
    
    return db






if __name__ == '__main__':

    # set up logging
    logging.basicConfig(filename='log_file.log')
    logger = logging.getLogger('logger')
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    

    # create formatter
    formatter = logging.Formatter('%(asctime)s [%(levelname)s]:  %(message)s', '%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    

    host = '127.0.0.1'
    port = 8080
    app.run(host=host, debug=True, threaded=True, port=port)
    logger.info(f'API v1.1 online: http://{host}:{port}')