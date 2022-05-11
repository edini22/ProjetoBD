from urllib import response
from attr import define
from flask import Flask, request, jsonify
from re import A
import datetime
from email import utils
from functools import wraps
import flask
import jwt
import psycopg2
import logging

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

# FIXME: verificar os endpoints onde esta dbproj


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
    def decorator(*args,**kwargs):

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

        return f(array[0], array[1],*args,**kwargs)

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


# http://localhost:8080/user/
@app.route('/user/', methods=['PUT'])
def signIn():
    """Login do utilizador"""
    logger.info('PUT /user/')
    payload = flask.request.get_json()

    conn = db_connection()
    cur = conn.cursor()

    logger.debug(f'PUT /user/ - payload: {payload}')

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
        res = cur.execute(statement, values)
        row = cur.fetchall()
        if row[0][0] == "ERRO":
            response = {'status': StatusCodes['api_error'],
                        'results': f'username errado ou password incorreta!{row[0][0]}'}
            conn.rollback()
        else:
            cur.execute('SELECT ID_USER(%s)', (payload['username'],))
            rows = cur.fetchall()
            print(rows[0][0])
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

# http://localhost:8080/user/
# qualquer um pode se registar como comprador
# apenas admins adicionam admins e vendedores
@app.route('/user/', methods=['POST'])
@verify_token_login
def new_user(type_user):
    logger.info('POST /user')
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
        reponse = {'Status': StatusCodes['internal_error'],
                   'error': 'vendedores nao têm este acesso!'}
        return flask.jsonify(response)

    addAdmin = 'SELECT ADD_ADMIN(%s,%s,%s);'
    addcomp = 'SELECT ADD_COMPRADOR(%s,%s,%s,%s);'
    addvend = 'SELECT ADD_VENDEDOR(%s,%s,%s,%d);'

    conn = db_connection()
    cur = conn.cursor()
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
        reponse = {'Status': StatusCodes['success'],
                   'Results': f'{tipo} inserido!'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /user - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)

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
                row[3]), 'Stock': int(row[4]), 'Versao': int(row[5]), 'ID Vendedor': int(row[6])}
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
@verify_token
def get_all_users(user_id, type_user):
    logger.info('GET /utilizadores')

    # Verficar permissoes
    if(type_user == "comprador"):
        reponse = {
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
@verify_token
def get_all_buyers(user_id, type_user):
    logger.info('GET /compradores')

    # Verficar permissoes
    if(type_user == "comprador"):
        reponse = {
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
@verify_token
def get_all_sellers(user_id, type_user):
    logger.info('GET /vendedores')

    # Verficar permissoes
    if(type_user == "comprador"):
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': "compradores nao têm este acesso!"}
        return jsonify(response)

    if(type_user == "vendedor"):
        reponse = {
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

# http://localhost:8080/produto/
@app.route('/produto/', methods=['POST'])
@verify_token
def new_product(user_id, type_user):
    logger.info('POST /produto')
    payload = flask.request.get_json()

    # Verficar permissoes
    if(type_user != "vendedor"):
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': "Apenas Vendedores podem adicionar produtos!"}
        return jsonify(reponse)

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
    try:
        cur.execute('SELECT max_id();')
        idd = int(cur.fetchall()[0][0])+1
        print(idd)

        if(payload['tipo'] == "computador"):
            add = 'SELECT add_computador(%s,1,%s,%s,%s,%s,%s,%s,%s,%s,%s);'
            
            values = (idd,payload['nome'], payload['descricao'], float(payload['preco']), int(payload['stock']), int(
                user_id), payload['processador'], int(payload['ram']), int(payload['rom']), payload['grafica'])
            cur.execute(add, values)

        elif(payload['tipo'] == "telemovel"):
            add = 'SELECT add_telemovel(%s,1,%s,%s,%s,%s,%s,%s,%s,%s);'
            values = (idd,payload['nome'], payload['descricao'], float(payload['preco']), int(payload['stock']), int(
                user_id), float(payload['tamanho']), int(payload['ram']), int(payload['rom']))
            cur.execute(add, values)

        else:
            add = 'SELECT add_televisao(%s,1,%s,%s,%s,%s,%s,%s,%s);'
            values = (idd,payload['nome'], payload['descricao'], float(payload['preco']), int(
                payload['stock']), int(user_id), float(payload['tamanho']), payload['resolucao'])
            cur.execute(add, values)
        tipo = payload['tipo']
        reponse = {'Status': StatusCodes['success'],
                   'Results': f'{tipo} inserido!'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'GET /produtos - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)


# http://localhost:8080/produto/{produto_id}

# TODO: Mudar f strings para proteger de ataques
@app.route('/produtos/<produto_id>', methods=['PUT'])
@verify_token
def change_product(user_id, type_user,produto_id):
    logger.info('PUT /poduto/<produto_id>')
    payload = flask.request.get_json()

    # Verificar permissoes
    if type_user != "vendedor":
        response = {'Status': StatusCodes['internal_error'],
                    'error': "Apenas Vendedores podem alterar produtos."}
        return jsonify(response)

    # Verificar se algum dos paremetros esta no body da mensagem
    lista = ['nome', 'descricao', 'preco', 'stock', 'processador', 'ram', 'rom', 'grafica', 'tamanho', 'resolucao']
    count = 0
    for i in lista:
        if i not in payload:
            count +=1
    if count == len(lista):
        response = {'Status': StatusCodes['internal_error'],
                    'error': "Nenhum parametro correto para atualizar o produto."}
        return jsonify(response)
    

    conn = db_connection()
    cur = conn.cursor()
    try: 
        # Verificar se o user é vendedor do produto
        cur.execute('SELECT vendedor_id FROM produtos WHERE %s = vendedor_id;', user_id)
        vendedor_id = cur.fetchall()[0][0]
        if vendedor_id != int(user_id):
            response = {'Status': StatusCodes['internal_error'],
                        'error': "Nao tem permissao para alterar este produto."}
            return jsonify(response)

        # Selecionar os dados da versao anterior do produto
        cur.execute('SELECT nome FROM produtos WHERE id = %s;', produto_id)
        nome = cur.fetchall()
        nome = nome[0][0]

        cur.execute('SELECT descricao FROM produtos WHERE id = %s;', produto_id)
        descricao = cur.fetchall()
        descricao = descricao[0][0]

        cur.execute('SELECT preco FROM produtos WHERE id = %s;', produto_id)
        preco = cur.fetchall()
        preco = preco[0][0]

        cur.execute('SELECT stock FROM produtos WHERE id = %s;', produto_id)
        stock = cur.fetchall()
        stock = stock[0][0]

        cur.execute('SELECT versao FROM produtos WHERE id = %s;', produto_id)
        versao = cur.fetchall()
        versao = versao[0][0] + 1  # aumentar a versao em 1 valor

        cur.execute('SELECT GET_TIPO(%s);', produto_id)
        tipo = cur.fetchall()
        tipo = tipo[0][0]

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
            cur.execute('SELECT c.processador FROM computadores c WHERE c.produto_id = %s;', produto_id)
            processador = cur.fetchall()
            processador = processador[0][0]

            cur.execute('SELECT c.ram FROM computadores c WHERE c.produto_id = %s;', produto_id)
            ram = cur.fetchall()
            ram = ram[0][0]

            cur.execute('SELECT c.rom FROM computadores c WHERE c.produto_id = %s;', produto_id)
            rom = cur.fetchall()
            rom = rom[0][0]

            cur.execute('SELECT c.processador FROM computadores c WHERE c.produto_id = %s;', produto_id)
            grafica = cur.fetchall()
            grafica = grafica[0][0]

            if 'processador' in payload:
                processador = payload['processador']
            
            if 'ram' in payload:
                ram = payload['ram']

            if 'rom' in payload:
                rom = payload['rom']

            if 'grafica' in payload:
                grafica = payload['grafica']
            
            add = 'SELECT add_computador(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);'
            values = (produto_id, versao, nome, descricao, preco, stock, user_id, processador, ram, rom, grafica)
            cur.execute(add,values)
                
            response = {'Status': StatusCodes['success'],'Results': f'Produto \'{nome}\' atualizado'}

        elif tipo == 'telemovel':
            cur.execute('SELECT tamanho FROM telemoveis WHERE id = %s;', produto_id)
            tamanho = cur.fetchall()
            tamanho = tamanho[0][0]

            cur.execute('SELECT ram FROM telemoveis WHERE id = %s;', produto_id)
            ram = cur.fetchall()
            ram = ram[0][0]

            cur.execute('SELECT rom FROM telemoveis WHERE id = %s;', produto_id)
            rom = cur.fetchall()
            rom = rom[0][0]

            if 'tamanho' in payload:
                tamanho = payload['rom']

            if 'ram' in payload:
                ram = payload['ram']

            if 'rom' in payload:
                rom = payload['rom']

            cur.execute('SELECT add_telemovel(%s,%s, %s, %s, %s, %s, %s, %s, %s, %s);',
                        produto_id, versao, nome, descricao, preco, stock, user_id, tamanho, ram, rom)
            response = {'Status': StatusCodes['success'],'Results': f'Produto \'{nome}\' atualizado'}

        elif tipo == 'televisao':
            cur.execute('SELECT tamanho FROM televisoes WHERE id = %d;', produto_id)
            tamanho = cur.fetchall()
            tamanho = tamanho[0][0]

            cur.execute('SELECT resolucao FROM televisoes WHERE id = %d;', produto_id)
            resolucao = cur.fetchall()
            resolucao = resolucao[0][0]

            if 'tamanho' in payload:
                tamanho = payload['rom']

            if 'resolucao' in payload:
                resolucao = payload['resolucao']

            cur.execute('SELECT add_telemovel(%s, %s, %s, %s, %s, %s, %s, %s, %s);',
                        produto_id, nome, descricao, preco, stock, user_id, tamanho, resolucao)
            response = {'Status': StatusCodes['success'],'Results': f'Produto \'{nome}\' atualizado'}
            
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

# http://localhost:8080/order


@app.route('/compra/', methods=['POST'])
@verify_token
def order(user_id, type_user):
    logger.info('POST /compra')
    payload = flask.request.get_json()

    if(type_user != "comprador"):
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': "Apenas Compradores podem efetuar compras!"}
        return jsonify(reponse)

    if 'cart' not in payload:
        response = {'status': StatusCodes['api_error'],
                    'results': 'cart is required to update'}
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

    add = 'SELECT add_compra(%s,%s);'
    values = (payload['cart'], user_id)

    conn = db_connection()
    cur = conn.cursor()  # TODO: FAZER AGR A FUNCAO SQL TP A DO DAVID
    try:
        cur.execute(add, values)

        reponse = {'Status': StatusCodes['success'],
                   'Results': 'Compra efetuada!'}

        conn.commit()

    except(Exception, psycopg2.DatabaseError) as error:
        logger.error(f'POST /compra - error: {error}')
        reponse = {
            'Status': StatusCodes['internal_error'], 'Error': str(error)}
        conn.rollback()

    finally:
        if conn is not None:
            conn.close()

    return flask.jsonify(reponse)

    return

# Rating =========================================================================

# http://localhost:8080/rating/{produto_id}


@app.route('/ratings/<produto_id>', methods=['POST'])
@verify_token
def rating(produto_id):
    logger.info(f'POST /ratings/{produto_id}')
    payload = flask.request.get_json()

    if 'valor' not in payload:
        reponse = {
            'Status': StatusCodes['internal_error'], 'error': "Tem de incluir o valor da rating"}
        return jsonify(reponse)
    pass

# Comentario =====================================================================

# http://localhost:8080/questions/{produto_id}
# http://localhost:8080/questions/{produto_id}/{comentario_pai_id}


@app.route('/comentario_normal/<produto_id>', methods=['POST'])
def comment(produto_id):
    # TODO:
    pass


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
