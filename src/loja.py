from flask import Flask, request, jsonify
import datetime
from functools import wraps
import flask
import jwt
import psycopg2
import logging
import json

# pip install PyJWT

app = flask.Flask(__name__)
# imports

StatusCodes = {
    'success': 200,
    'api_error': 400,
    'internal_error': 500
}

global f

# Acesso a DataBase
# DEBUG: comprador pode fazer varios ratings!!
# rating pode ser uma chave fraca
# produtos, retirar a tabela do historico e colocar um atributo de versao!, retirar o id de unique!!
# alguns autoincremnete, é melhor retirar !!


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


@app.route('/')
def landing_page():
    return """
    Bem vindo à loja DataStore!
    Comece as suas compras assim que possível :)

    Para se registar use o Endpoint http://localhost:8080/user/ (POST)
    Para se autenticar use o Endpoint http://localhost:8080/user/ (PUT)

    Fábio Santos 2020212310
    Eduardo Figueiredo 2020213717
    """

# LOGIN ==========================================================================


def generate_token(user_id, type_user):

    payload = {
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1),
        'sub': str(user_id)+';'+str(type_user)
    }

    return jwt.encode(payload, "SECRET_KEY", algorithm='HS256')


def verify_token(f):
    @wraps(f)
    def decorator(*args, **kwargs):

        token = None
        if 'Authorization' not in request.headers or not request.headers['Authorization']:
            return jsonify({'status': StatusCodes['api_error'], 'errors': 'token is missing'})

        token = request.headers['Authorization'].split(" ")[1]

        try:
            payload = jwt.decode(
                token,
                "SECRET_KEY",
                algorithms=['HS256']
            )
            sub = payload['sub']
            array = sub.split(";")

        except jwt.ExpiredSignatureError:
            type_user = ""
            return jsonify({'status': StatusCodes['api_error'], 'errors': 'token expired'})

        except jwt.InvalidTokenError:
            type_user = ""
            return jsonify({'status': StatusCodes['api_error'], 'errors': 'invalid token'})

        return f(array[0], array[1], *args, **kwargs)

    return decorator


def verify_token_login(f):
    @wraps(f)
    def decorator():
        array = []
        token = None
        if 'Authorization' not in request.headers or not request.headers['Authorization']:
            array.append("logout")
        else:

            token = request.headers['Authorization'].split(" ")[1]

            try:
                payload = jwt.decode(
                    token,
                    "SECRET_KEY",
                    algorithms=['HS256']
                )
                sub = payload['sub']
                aux = sub.split(";")
                array.append(aux[1])

            except jwt.ExpiredSignatureError:
                type_user = ""
                return jsonify({'status': StatusCodes['api_error'], 'errors': 'token expired'})

            except jwt.InvalidTokenError:
                type_user = ""
                return jsonify({'status': StatusCodes['api_error'], 'errors': 'invalid token'})

        return f(array[0])

    return decorator


# http://localhost:8080/dbproj/user
@app.route('/dbproj/user', methods=['PUT'])
def signIn():
    """Login do utilizador"""
    logger.info('PUT /dbproj/user')
    payload = flask.request.get_json()

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'PUT /dbproj/user/ - payload: {payload}')

    if 'username' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'username is required to update'}
        return flask.jsonify(response)
    if 'password' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'password is required to update'}
        return flask.jsonify(response)

     # parameterized queries, good for security and performance
    statement = 'SELECT LOGIN_VERIFY(%s,%s);'
    values = (payload['username'], payload['password'])

    try:
        cur.execute(statement, values)
        row = cur.fetchall()
        if row[0][0] == "ERRO":
            response = {'status': StatusCodes['api_error'],
                        'results': f'username errado ou password incorreta!{row[0][0]}'}
            conn.rollback()
        else:
            cur.execute('SELECT ID_USER(%s)', (payload['username'],))
            rows = cur.fetchall()
            token = generate_token(str(rows[0][0]), str(row[0][0]))
            conn.commit()
            return flask.jsonify({'authToken': token})

    except (Exception, psycopg2.DatabaseError) as error:
        logger.error(error)
        response = {
            'status': StatusCodes['internal_error'], 'errors': str(error)}

        # an error occurred, rollback
        conn.rollback()
    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)

# http://localhost:8080/dbproj/user
# qualquer um pode se registar como comprador
# apenas admins adicionam admins e vendedores


@app.route('/dbproj/user', methods=['POST'])
@verify_token_login
def new_user(type_user):
    logger.info('POST /dbproj/user')
    payload = flask.request.get_json()

    # Verificar todos os parametros para adicionar user
    if 'username' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'username is required to update'}
        return flask.jsonify(response)

    if 'password' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'password is required to update'}
        return flask.jsonify(response)

    if 'nome' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'nome is required to update'}
        return flask.jsonify(response)

    if 'tipo' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'tipo is required to update'}
        return flask.jsonify(response)

    # Verificar as permissoes para adicionar tipos de users
    if(payload['tipo'] == "comprador"):
        if 'morada' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'morada is required to update'}
            return flask.jsonify(response)

    elif(payload['tipo'] == "vendedor"):
        if(type_user != "admin"):
            return jsonify({'status': StatusCodes['api_error'], 'errors': 'wrong user type'})
        if 'nif' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'nif is required to update'}
            return flask.jsonify(response)

    elif(payload['tipo'] == "admin"):
        if(type_user != "admin"):
            return jsonify({'status': StatusCodes['api_error'], 'errors': 'wrong user type'})
    else:
        response = {'status': StatusCodes['api_error'],
                    'results': 'tipo incorreto(admin/comprador/utilizador)'}
        return flask.jsonify(response)

    if ((payload['tipo'] == "admin" or payload['tipo'] == "vendedor") and type_user == "vendedor"):
        response = {'Status': StatusCodes['internal_error'],
                   'error': 'vendedores nao têm este acesso!'}
        return flask.jsonify(response)

    addAdmin = 'CALL ADD_ADMIN(%s,%s,%s);'
    addcomp = 'CALL ADD_COMPRADOR(%s,%s,%s,%s);'
    addvend = 'CALL ADD_VENDEDOR(%s,%s,%s,%d);'

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/user - payload: {payload}')
    try:
        if(payload['tipo'] == "admin"):
            valuesadmin = (payload['username'],
                           payload['password'], payload['nome'])
            cur.execute(addAdmin, valuesadmin)
        elif(payload['tipo'] == "comprador"):
            valuescomp = (payload['username'], payload['password'],
                          payload['nome'], payload['morada'])
            cur.execute(addcomp, valuescomp)
        else:
            valuesvend = (payload['username'], payload['password'],
                          payload['nome'], int(payload['nif']))
            cur.execute(addvend, valuesvend)
        tipo = payload['tipo']
        nome = payload['username']
        response = {'Status': StatusCodes['success'],
                   'Results': f'{tipo} inserido!{nome}'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)

# GET's ==========================================================================

# http://localhost:8080/dbproj/produtos


@app.route('/dbproj/produtos', methods=['GET'])
def get_all_produts():
    logger.info('GET /dbproj/produtos')
    conn = db_connection()
    cur = conn.cursor()

    try:

        cur.execute('SELECT * FROM produtos')
        rows = cur.fetchall()

        logger.debug('GET /produtos - parse')
        Results = []
        for row in rows:
            # Argumentos Gerais
            content = {'ID': int(row[0]), 'Nome': row[1], 'Descricao': row[2], 'Preco': int(
                row[3]), 'Stock': int(row[4]), 'Versao': int(row[5]), 'ID Vendedor': int(row[6])}

            # Argumentos particulares
            cur.execute('SELECT GET_TIPO(%s);', (int(row[0]),))
            tipo = cur.fetchall()[0][0]

            if tipo == 'computador':
                cur.execute(
                    'SELECT * FROM computadores c WHERE c.produto_id = %s AND c.produto_versao = %s;', (row[0], row[5]))
                row2 = cur.fetchall()
                aux = {'Processador': row2[0][0], 'Ram': int(
                    row2[0][1]), 'Rom': int(row2[0][2]), 'Grafica': row2[0][3]}
                content.update(aux)

            elif tipo == 'telemovel':
                cur.execute(
                    'SELECT * FROM telemoveis t WHERE t.produto_id = %s AND t.produto_versao = %s;', (row[0], row[5]))
                row2 = cur.fetchall()
                aux = {'Tamanho': float(row2[0][0]), 'Ram': int(
                    row2[0][1]), 'Rom': int(row2[0][2])}
                content.update(aux)

            elif tipo == 'televisao':
                cur.execute(
                    'SELECT * FROM televisoes t WHERE t.produto_id = %s AND t.produto_versao = %s;', (row[0], row[5]))
                row2 = cur.fetchall()
                aux = {'Tamanho': float(
                    row2[0][0]), 'Resolucao': int(row2[0][1])}
                content.update(aux)

            Results.append(content)

        response = {'Status': StatusCodes['success'], 'Results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /produtos - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/utilizadores

@app.route('/dbproj/utilizadores', methods=['GET'])
@verify_token
def get_all_users(user_id, type_user):
    logger.info('GET /dbproj/utilizadores')

    # Verficar permissoes
    if(type_user == "comprador"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "compradores nao têm este acesso!"}
        return jsonify(response)

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

        response = {'Status': StatusCodes['success'], 'results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /utilizadores - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/compradores

@app.route('/dbproj/compradores', methods=['GET'])
@verify_token
def get_all_buyers(user_id, type_user):
    logger.info('GET /dbproj/compradores')

    # Verficar permissoes
    if(type_user == "comprador"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "compradores nao têm este acesso!"}
        return jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    try:

        cur.execute(
            'SELECT u.nome, u.id, u.username, c.morada FROM utilizadores u, compradores c WHERE u.id = c.utilizador_id')
        rows = cur.fetchall()

        logger.debug('GET /compradores - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'Nome': row[0], 'ID': int(
                row[1]), 'Username': row[2], 'Morada': row[3]}
            Results.append(content)

        response = {'Status': StatusCodes['success'], 'results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /compradores - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/vendedores

@app.route('/dbproj/vendedores', methods=['GET'])
@verify_token
def get_all_sellers(user_id, type_user):
    logger.info('GET /dbproj/vendedores')

    # Verficar permissoes
    if(type_user == "comprador"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "compradores nao têm este acesso!"}
        return jsonify(response)

    if(type_user == "vendedor"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "vendedorres nao têm este acesso!"}
        return jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    try:

        cur.execute(
            'SELECT u.nome, u.id, u.username, v.nif FROM utilizadores u, vendedores v WHERE utilizadores.id = v.utilizador_id')
        rows = cur.fetchall()

        logger.debug('GET /vendedores - parse')
        Results = []
        for row in rows:
            logger.debug(row)
            content = {'Nome': row[0], 'ID': int(
                row[1]), 'Username': row[2], 'NIF': row[3]}
            Results.append(content)

        response = {'Status': StatusCodes['success'], 'results': Results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /vendedores - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'error': str(error)}

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# Produtos =======================================================================

# http://localhost:8080/dbproj/product
@app.route('/dbproj/product', methods=['POST'])
@verify_token
def new_product(user_id, type_user):
    logger.info('POST /dbproj/product')
    payload = flask.request.get_json()

    # Verficar permissoes
    if(type_user != "vendedor"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Apenas Vendedores podem adicionar produtos!"}
        return jsonify(response)

    # Verficar dados
    if 'nome' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'nome is required to update'}
        return flask.jsonify(response)

    if 'descricao' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'descricao is required to update'}
        return flask.jsonify(response)

    if 'preco' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'preco is required to update'}
        return flask.jsonify(response)

    if 'stock' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'stock is required to update'}
        return flask.jsonify(response)

    if 'tipo' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'tipo is required to update'}
        return flask.jsonify(response)

    if(payload['tipo'] == "computador"):
        if 'processador' not in payload:
            response = {'status': StatusCodes['api_error'],
                        'results': 'processador is required to update'}
            return flask.jsonify(response)
        if 'ram' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'ram is required to update'}
            return flask.jsonify(response)
        if 'rom' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'rom is required to update'}
            return flask.jsonify(response)

        if 'grafica' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'grafica is required to update'}
            return flask.jsonify(response)

    elif(payload['tipo'] == "telemovel"):
        if 'tamanho' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'tamanho is required to update'}
            return flask.jsonify(response)

        if 'ram' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'ram is required to update'}
            return flask.jsonify(response)
        if 'rom' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'rom is required to update'}
            return flask.jsonify(response)

    elif(payload['tipo'] == "televisao"):
        if 'tamanho' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'tamanho is required to update'}
            return flask.jsonify(response)

        if 'resolucao' not in payload:
            response = {
                'status': StatusCodes['api_error'], 'results': 'resolucao is required to update'}
            return flask.jsonify(response)

    else:
        response = {'status': StatusCodes['api_error'],
                    'results': 'tipo incorreto(computador/telemovel/televisao)'}
        return flask.jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/product - payload: {payload}')
    try:
        cur.execute('SELECT max_id();')
        idd = int(cur.fetchall()[0][0])+1

        if(payload['tipo'] == "computador"):
            add = 'CALL add_computador(%s,1,%s,%s,%s,%s,%s,%s,%s,%s,%s);'

            values = (idd, payload['nome'], payload['descricao'], float(payload['preco']), int(payload['stock']), int(
                user_id), payload['processador'], int(payload['ram']), int(payload['rom']), payload['grafica'])
            cur.execute(add, values)

        elif(payload['tipo'] == "telemovel"):
            add = 'CALL add_telemovel(%s,1,%s,%s,%s,%s,%s,%s,%s,%s);'
            values = (idd, payload['nome'], payload['descricao'], float(payload['preco']), int(payload['stock']), int(
                user_id), float(payload['tamanho']), int(payload['ram']), int(payload['rom']))
            cur.execute(add, values)

        else:
            add = 'CALL add_televisao(%s,1,%s,%s,%s,%s,%s,%s,%s);'
            values = (idd, payload['nome'], payload['descricao'], float(payload['preco']), int(
                payload['stock']), int(user_id), float(payload['tamanho']), payload['resolucao'])
            cur.execute(add, values)
        tipo = payload['tipo']
        response = {'Status': StatusCodes['success'],
                   'Results': f'{tipo} inserido!'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /produtos - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/product/{product_id}
@app.route('/dbproj/product/<produto_id>', methods=['PUT'])
@verify_token
def change_product(user_id, type_user, produto_id):
    logger.info('PUT /dbproj/product/<produto_id>')
    payload = flask.request.get_json()

    # Verificar permissoes
    if type_user != "vendedor":
        response = {'Status': StatusCodes['internal_error'],
                    'error': "Apenas Vendedores podem alterar produtos."}
        return jsonify(response)

    # Verificar se algum dos paremetros esta no body da mensagem
    lista = ['nome', 'descricao', 'preco', 'stock', 'processador',
             'ram', 'rom', 'grafica', 'tamanho', 'resolucao']
    count = 0
    for i in lista:
        if i not in payload:
            count += 1
    if count == len(lista):
        response = {'Status': StatusCodes['internal_error'],
                    'error': "Nenhum parametro correto para atualizar o produto."}
        return jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'PUT /dbproj/product/{produto_id} - payload: {payload}')

    try:
        # Verificar se o user é vendedor do produto
        cur.execute(
            'SELECT vendedor_id FROM produtos WHERE %s = vendedor_id;', (user_id,))
        vendedor_id = cur.fetchall()[0][0]
        if vendedor_id != int(user_id):
            response = {'Status': StatusCodes['internal_error'],
                        'error': "Nao tem permissao para alterar este produto."}
            return jsonify(response)

        # Selecionar os dados da versao anterior do produto
        cur.execute(
            'SELECT  MAX(versao) FROM produtos  WHERE id = %s ;', (produto_id,))
        versao = cur.fetchall()[0][0]

        sel = 'SELECT p.nome, p.descricao, p.preco, p.stock FROM produtos p WHERE p.id = %s and p.versao = %s;'
        variaveis = (produto_id, versao)
        cur.execute(sel, variaveis)
        row = cur.fetchall()
        nome = row[0][0]
        descricao = row[0][1]
        preco = row[0][2]
        stock = row[0][3]

        cur.execute('SELECT GET_TIPO(%s::INTEGER);', (produto_id,))
        tipo = cur.fetchall()
        tipo = tipo[0][0]
        print(tipo)

        # Atualizar os dados para a nova versao do produto
        if 'nome' in payload:
            nome = payload['nome']

        if 'descricao' in payload:
            nome = payload['descricao']

        if 'preco' in payload:
            nome = payload['preco']

        if 'stock' in payload:
            nome = payload['stock']

        if tipo == 'computador':
            var = 'SELECT c.processador, c.ram, c.rom, c.grafica FROM computadores c WHERE c.produto_id = %s and c.produto_versao = %s;'
            val = (produto_id, versao)
            cur.execute(var, val)
            rows = cur.fetchall()
            processador = rows[0][0]
            ram = rows[0][1]
            rom = rows[0][2]
            grafica = rows[0][3]

            versao += 1  # aumentar a versao em 1 valor

            if 'processador' in payload:
                processador = payload['processador']

            if 'ram' in payload:
                ram = payload['ram']

            if 'rom' in payload:
                rom = payload['rom']

            if 'grafica' in payload:
                grafica = payload['grafica']

            add = 'CALL add_computador(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);'
            values = (produto_id, versao, nome, descricao, preco,
                      stock, user_id, processador, ram, rom, grafica)
            cur.execute(add, values)

            response = {
                'Status': StatusCodes['success'], 'Results': f'Produto \'{nome}\' atualizado'}

        elif tipo == 'telemovel':
            var = 'SELECT t.tamanho,t.ram,t.rom FROM telemoveis t WHERE t.produto_id = %s and t.produto_versao = %s;'
            val = (produto_id, versao)
            cur.execute(var, val)
            rows = cur.fetchall()
            tamanho = rows[0][0]
            ram = rows[0][1]
            rom = rows[0][2]

            if 'tamanho' in payload:
                tamanho = payload['rom']

            if 'ram' in payload:
                ram = payload['ram']

            if 'rom' in payload:
                rom = payload['rom']

            versao += 1  # aumentar a versao em 1 valor

            cur.execute('CALL add_telemovel(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);',
                        (produto_id, versao, nome, descricao, preco, stock, user_id, tamanho, ram, rom))
            response = {
                'Status': StatusCodes['success'], 'Results': f'Produto \'{nome}\' atualizado'}

        elif tipo == 'televisao':
            var = 'SELECT t.tamanho,t.resolucao FROM televisoes t WHERE t.produto_id = %s and t.produto_versao = %s;'
            val = (produto_id, versao)
            cur.execute(var, val)
            rows = cur.fetchall()
            tamanho = rows[0][0]
            resolucao = rows[0][1]

            if 'tamanho' in payload:
                tamanho = payload['rom']

            if 'resolucao' in payload:
                resolucao = payload['resolucao']

            versao += 1  # aumentar a versao em 1 valor

            cur.execute('CALL add_televisao(%s, %s, %s, %s, %s, %s, %s, %s, %s);',
                        (produto_id, versao, nome, descricao, preco, stock, user_id, tamanho, resolucao))
            response = {
                'Status': StatusCodes['success'], 'Results': f'Produto \'{nome}\' atualizado'}

            conn.commit()
    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# Compra =========================================================================

# http://localhost:8080/dbproj/order

@app.route('/dbproj/order', methods=['POST'])
@verify_token
def order(user_id, type_user):
    logger.info('POST /dbproj/order')
    payload = flask.request.get_json()

    if(type_user != "comprador"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Apenas Compradores podem efetuar compras!"}
        return jsonify(response)

    if 'cart' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'cart is required to update'}
        return flask.jsonify(response)

    if(len(payload['cart']) == 0):
        response = {'status': StatusCodes['api_error'],
                    'results': 'Adicione itens ao seu carrinho'}
        return flask.jsonify(response)

    for i in range(len(payload['cart'])):
        if 'quantidade' not in payload['cart'][i]:
            response = {'status': StatusCodes['api_error'],
                        'results': 'quantidade is required to update'}
            return flask.jsonify(response)
        if 'product_id' not in payload['cart'][i]:
            response = {'status': StatusCodes['api_error'],
                        'results': 'product_id is required to update'}
            return flask.jsonify(response)

    add = 'CALL add_compra(%s,%s);'
    values = (json.dumps(payload['cart']), user_id)

    conn = db_connection()
    cur = conn.cursor() 

    logger.debug(f'POST /dbproj/order - payload: {payload}')

    try:
        cur.execute(add, values)
        response = {'Status': StatusCodes['success'],
                   'Results': 'Compra efetuada!'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /compra - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# Rating =========================================================================

# http://localhost:8080/dbproj/rating/{product_id}

@app.route('/dbproj/rating/<produto_id>', methods=['POST'])
@verify_token
def rating(user_id, type_user, produto_id):
    logger.info(f'POST /dbproj/rating/{produto_id}')
    payload = flask.request.get_json()

    if type_user != 'comprador':
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Apenas um comprador pode avaliar produtos"}
        return jsonify(response)

    if 'valor' not in payload:
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Tem de incluir o valor do rating"}
        return jsonify(response)

    if 'comentario' not in payload:
        comentario = ' '
    else:
        comentario = payload['comentario']

    valor = payload['valor']

    if valor > 5 or valor < 1:
        response = {
            'Status': StatusCodes['internal_error'], 'error': "O valor do rating tem de estar entre 1 e 5"}
        return jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/rating/{produto_id} - payload: {payload}')

    try:
        statement = "SELECT user_bought_product(%s,%s)"
        values = (user_id, produto_id)
        # Funcao devolve 0 se nunca comprou o produto, caso contrario devolve a versao que comprou
        # FIXME: verificar o que acontece se o comprador comprar duas versoes diferentes do mesmo produto
        cur.execute(statement, values)
        versao = cur.fetchall()[0][0]
        #print(f"DEBUG: Versao -> {versao}")

        if(versao == 0):
            response = {
                'Status': StatusCodes['internal_error'], 'error': "Para avaliar um produto tem de o comprar"}
            return jsonify(response)

        cur.execute("call add_rating(%s, %s, %s, %s, %s)",
                    (valor, comentario, user_id, produto_id, versao))

        response = {'Status': StatusCodes['success'],
                    'Results': "Rating inserido com sucesso"}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/rating/{product_id}

@app.route('/dbproj/rating/<produto_id>', methods=['GET'])
def see_ratings(produto_id):
    logger.info(f'GET /dbproj/rating/{produto_id}')

    conn = db_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            'SELECT r.valor, r.comentario, r.comprador_id FROM ratings r WHERE r.produto_id = %s;', (produto_id,))
        rows = cur.fetchall()
        results = []

        for row in rows:
            content = {'Valor': int(
                row[0]), 'Comentario': row[1], 'ID Comprador': row[2]}
            results.append(content)

        if results == []:  # rows == None
            response = {
                'Status': StatusCodes['internal_error'], 'Resultado': 'O produto nao tem ratings'}
            return flask.jsonify(response)

        response = {'Status': StatusCodes['success'], 'Results': results}

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# Comentario =====================================================================
# http://localhost:8080/dbproj/questions/{product_id}

@app.route('/dbproj/questions/<produto_id>', methods=['POST'])
@verify_token
def comment1(user_id, type_user, produto_id):
    logger.info(f'POST /dbproj/questions/{produto_id}')
    payload = flask.request.get_json()

    if 'texto' not in payload:
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Tem de incluir texto no seu comentario"}
        return jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/questions/{produto_id} - payload: {payload}')

    try:
        statement = 'CALL add_comentario1(%s, %s, %s)'
        values = (payload['texto'], user_id, produto_id)

        cur.execute(statement, values)

        response = {'Status': StatusCodes['success'],
                    'Results': 'Comentario adicionado com sucesso'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/questions/{product_id}/{parent_question_id}

@app.route('/dbproj/questions/<produto_id>/<comentario_pai_id>', methods=['POST'])
@verify_token
def comment2(user_id, type_user, produto_id, comentario_pai_id):
    logger.info(f'POST /dbproj/dbproj/questions/{produto_id}/{comentario_pai_id}')
    payload = flask.request.get_json()

    if 'texto' not in payload:
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Tem de incluir texto no seu comentario"}
        return jsonify(response)

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'POST /dbproj/questions/{produto_id}/{comentario_pai_id} - payload: {payload}')

    try:
        statement = 'CALL add_comentario2(%s, %s, %s, %s)'
        values = (payload['texto'], user_id, produto_id, comentario_pai_id)

        cur.execute(statement, values)

        response = {'Status': StatusCodes['success'],
                    'Results': 'Comentario resposta adicionado com sucesso'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/questions/{product_id}

@app.route('/dbproj/questions/<produto_id>', methods=['GET'])
def see_comments(produto_id):
    logger.info(f'GET /dbproj/questions/{produto_id}')

    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute(
            'SELECT c.id, c.texto, c.utilizador_id, c.comentario_pai_id FROM comentarios c WHERE c.produto_id = %s ORDER BY c.comentario_pai_id ASC', produto_id)
        rows = cur.fetchall()

        logger.debug('GET /dbproj/comentario - parse')
        Results = []
        for row in rows:
            idd = row[0]
            texto = row[1]
            utilizador = row[2]
            comentario_pai = row[3]
            logger.debug(row)

            if comentario_pai == None:
                content = {'ID': int(idd), 'Texto': texto,
                           'Utilizador': utilizador}
            else:
                content = {'ID': int(
                    idd), 'Texto': texto, 'Utilizador': utilizador, 'ID Comentario pai': comentario_pai}
            Results.append(content)
        
        if Results == []: 
            response = {
                'Status': StatusCodes['internal_error'], 'Resultado': 'O produto nao tem comentarios'}
            return flask.jsonify(response)

        response = {'Status': StatusCodes['success'], 'results': Results}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/notificacoes

@app.route('/dbproj/notificacoes', methods=['GET'])
@verify_token
def see_notifications(user_id, type_user):
    logger.info(f'GET /dbproj/notificacoes/')

    conn = db_connection()
    cur = conn.cursor()

    try:
        # TODO: ver apenas as que nao foram vistas
        cur.execute('SELECT n.id, n.texto, n.data from notificacoes n WHERE n.utilizador_id = %s and n.vista = false;', (user_id,))
        rows = cur.fetchall()
        results = []

        for row in rows:
            content = {'ID': row[0], 'Notificacao': row[1], 'Data': row[2]}
            results.append(content)

        if results == []:
            response = {
                'Status': StatusCodes['internal_error'], 'Resultado': 'Voce nao tem notificacoes'}
            return flask.jsonify(response)

        response = {'Status': StatusCodes['success'], 'Results': results}

        cur.execute('CALL notificacao_vista(%s);', (user_id,))

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/product/{product_id}
@app.route('/dbproj/product/<produto_id>', methods=['GET'])
def get_product(produto_id):
    logger.info(f'GET /dbproj/product/{produto_id}')

    
    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT GET_PRODUCT(%s)', produto_id)
        rows = cur.fetchall()[0][0]

        logger.debug('GET /comentario - parse')
        
        if rows == None:
            response = {
                'Status': StatusCodes['internal_error'], 'Resultado': f'Nao existe nenhum produto com o id {produto_id}'}
            return flask.jsonify(response)


        response = {'Status': StatusCodes['success'], 'results': rows}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(response)


# http://localhost:8080/dbproj/report/year
@app.route('/dbproj/report/year', methods=['GET'])
@verify_token
def report_year(user_id, type_user):
    if(type_user != "admin"):
        response = {
            'Status': StatusCodes['internal_error'], 'error': "Apenas Admins podem efetuar esta operacao!"}
        return jsonify(response)

    logger.info('GET /dbproj/report/year')

    
    conn = db_connection()
    cur = conn.cursor()

    try:
        cur.execute('SELECT GET_report_year()')
        rows = cur.fetchall()[0][0]

        logger.debug('GET /comentario - parse')

        response = {'Status': StatusCodes['success'], 'results': rows}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        response = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()
    

# =============================================================================================================

# in psql , you can run “ \set AUTOCOMMIT off ”

if __name__ == '__main__':
    db = db_connection()
    db.set_session(autocommit=False)
    db.close()

    # set up logging
    logging.basicConfig(filename='log_file.log')
    logger = logging.getLogger('logger')
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)

    # create formatter
    formatter = logging.Formatter(
        '%(asctime)s [%(levelname)s]:  %(message)s', '%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    host = '127.0.0.1'
    port = 8080
    app.run(host=host, debug=True, threaded=True, port=port)
    logger.info(f'API v1.1 online: http://{host}:{port}')
