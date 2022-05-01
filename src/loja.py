from crypt import methods
import flask
import psycopg2
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
        user="aulaspl",
        password="aulaspl",
        host="127.0.0.1",
        port="5432",
        database="projetobd"
    )

    return db

# ENDPOINTS =#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

# FIXME: verificar os endpoints onde esta dbproj


@app.route('/')
def landing_page():
    return """
    Bem vindo à loja DataStore!
    Comece as suas compras assim que possível :)
    
    Para se registar use o Endpoint http://localhost:8080/dbproj/user (POST)
    Para se autenticar use o Endpoint http://localhost:8080/dbproj/user (PUT)
    
    Fábio Santos 2020212310
    Eduardo Figueiredo 2020213717
    """

# LOGIN ==========================================================================
# FIXME: verificar os endpoints onde esta dbproj


@app.route('/user/', methods=['POST'])
def new_user():
    # TODO:
    pass


@app.route('/user/', methods=['PUT'])
def login():
    # TODO:
    pass


# GET's ==========================================================================

# http://localhost:8080/produtos/

@app.route('/produtos/', methods=['GET'])
def get_all_produts():
    logger.info('GET /produtos')
    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT * FROM produtos')
        rows = cur.fetchall()

        logger.debug('GET /produtos - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'ID': int(row[0]), 'Nome': row[1], 'Descricao': row[2], 'Preco': int(
                row[3]), 'Stock': int(row[4]), 'ID Vendedor': int(row[5])}
            Results.append(content)

        reponse = {'Status': StatusCodes['success'], 'Results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /produtos - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)


# http://localhost:8080/utilizadores/

@app.route('/utilizadores/', methods=['GET'])
def get_all_users():
    logger.info('GET /utilizadores')
    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT nome, id, username  FROM utilizadores')
        rows = cur.fetchall()

        logger.debug('GET /utilizadores - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'Nome': row[0], 'ID': int(row[1]), 'Username': row[2]}
            Results.append(content)

        reponse = {'Status': StatusCodes['success'], 'results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /utilizadores - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)


# http://localhost:8080/compradores/

@app.route('/compradores/', methods=['GET'])
def get_all_buyers():
    logger.info('GET /compradores')
    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT utilizadores.nome, utilizadores.id, utilizadores.username, compradores.morada FROM utilizadores, compradores WHERE utilizadores.id = compradores.utilizador_id')
        rows = cur.fetchall()

        logger.debug('GET /compradores - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'Nome': row[0], 'ID': int(
                row[1]), 'Username': row[2], 'Morada': row[3]}
            Results.append(content)

        reponse = {'Status': StatusCodes['success'], 'results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /compradores - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)


# http://localhost:8080/vendedores/

@app.route('/vendedores/', methods=['GET'])
def get_all_sellers():
    logger.info('GET /compradores')
    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT utilizadores.nome, utilizadores.id, utilizadores.username, vendedores.nif FROM utilizadores, vendedores WHERE utilizadores.id = vendedores.utilizador_id')
        rows = cur.fetchall()

        logger.debug('GET /vendedores - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'Nome': row[0], 'ID': int(
                row[1]), 'Username': row[2], 'NIF': row[3]}
            Results.append(content)

        reponse = {'Status': StatusCodes['success'], 'results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /vendedores - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)


# Produtos =======================================================================

# http://localhost:8080/product
@app.route('/produto/', methods=['POST'])
def new_product():
    # TODO:
    pass

# http://localhost:8080/product/{produto_id}
@app.route('/produto/<produto_id>', methods=['PUT'])
def change_product(id_produto):
    # TODO:
    pass

# Compra =========================================================================

#http://localhost:8080/order
@app.rout('/compra/', methods=['POST'])
def order():
    # TODO:
    pass

# Rating =========================================================================

#http://localhost:8080/rating/{produto_id}
@app.route('/ratings/<produto_id>')
def rating(produto_id):
    # TODO:
    pass

# Comentario =====================================================================

# http://localhost:8080/questions/{produto_id}
# http://localhost:8080/questions/{produto_id}/{comentario_pai_id}

@app.route('/comentario_normal/<produto_id>')
def comment(produto_id):
    # TODO:
    pass



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
