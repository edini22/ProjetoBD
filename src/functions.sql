
-- LOGIN ===================================================================================================

--TODO: FAZER PROTECOES PARA VER SE ESSE PRODUTO AO INSERIR JA EXISTE!!!!

--retorna tipo de user se existir
DROP FUNCTION LOGIN_VERIFY;
CREATE OR REPLACE FUNCTION LOGIN_VERIFY(US VARCHAR,pass VARCHAR)
RETURNS VARCHAR
AS
$$
DECLARE
    tipo VARCHAR;
    idd INT := -1;
    cond INT := 0;
BEGIN 
    SELECT u.id INTO idd FROM utilizadores u, compradores c WHERE u.id = c.utilizador_id AND u.username = US and u.password like pass;
    IF idd > 0  THEN
        tipo := 'comprador';
        cond:=1;
    END IF;
    IF cond = 0  THEN
        SELECT u.id INTO idd FROM utilizadores u, vendedores v WHERE u.id = v.utilizador_id AND  u.username = US and u.password like pass ;
        IF  idd > 0  THEN
            tipo := 'vendedor';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0  THEN
        SELECT u.id INTO idd FROM utilizadores u, admins a WHERE  u.id = a.utilizador_id AND u.username = US and u.password like pass ;
        IF  idd > 0  THEN
            tipo:= 'admin';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0 THEN 
        tipo:= 'ERRO';
    END IF;

    RETURN tipo;
END;
$$ LANGUAGE plpgsql;

-- Devolve o tipo do produto atraves do user
DROP FUNCTION GET_TIPO;
CREATE OR REPLACE FUNCTION GET_TIPO(ID_PRODUTO INT)
RETURNS VARCHAR
AS
$$
DECLARE
    tipo VARCHAR;
    cond INT := 0;
    idd INT :=-1;
BEGIN 
    SELECT p.id INTO idd FROM produtos p, computadores c WHERE p.id = c.produto_id and p.id = ID_PRODUTO;
    IF idd > 0  THEN
        tipo := 'computador';
        cond:=1;
    END IF;
    IF cond = 0  THEN
        SELECT p.id INTO idd FROM produtos p, telemoveis t WHERE p.id = t.produto_id and p.id = ID_PRODUTO;
        IF idd > 0  THEN
            tipo := 'telemovel';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0 THEN
        SELECT p.id INTO idd FROM produtos p, televisoes t WHERE  p.id = t.produto_id and p.id = ID_PRODUTO;
        IF idd > 0 THEN
            tipo:= 'televisao';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0 THEN 
        tipo:= 'ERRO';
    END IF;

    RETURN tipo;
END;
$$ LANGUAGE plpgsql;


--COMPRA============================================================================ CURRENT_DATE

DROP FUNCTION get_preco;
CREATE FUNCTION get_preco(produtoID INT)
RETURNS float
AS
$$
DECLARE
    max_versao INT;
    preco INT;
    BEGIN
        SELECT MAX(p.versao) INTO max_versao FROM produtos p WHERE p.id = produtoID;
        SELECT p.preco INTO preco FROM produtos p WHERE p.id = produtoID AND p.versao = max_versao;
    RETURN preco;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION add_compra; 
CREATE  FUNCTION add_compra(js json ,Id_comprador INTEGER)
RETURNS VOID
AS
$$
DECLARE
    preco_total FLOAT := 0;--IGUALAR A 0 DEPOIS DE COLOCAR ITEMS
    idd INT;
    quant INTEGER;
    id_produto INTEGER;
    aux json;
    preco_produto FLOAT;
    vendedor INT;
    versao INT;
BEGIN
    --LOOP COM O JSON   #
    --VERIFICAR SE EXISTE ESSE PRODUTO !!
    INSERT INTO compras (compra_valor,compra_data,comprador_id) VALUES (0,CURRENT_DATE,Id_comprador);
    SELECT compra_id INTO idd FROM compras WHERE compra_valor = 0 and compra_data = CURRENT_DATE and comprador_id = Id_comprador;

    --loop com json adicionar a tabela itens 
    FOR c in 0..json_array_length(js)-1 LOOP
        aux := js::json->>c ;

        quant := aux::json->>'quantidade';
        id_produto:= aux::json->>'product_id';
        preco_produto :=  (get_preco(id_produto)*quant);
        preco_total = preco_total + preco_produto;
        --RAISE NOTICE 'quantidade - % , id - %,compra_id - %,preco - %',quant,id_produto,idd,preco_produto;
        SELECT p.vendedor_id into vendedor  FROM produtos p where p.id = id_produto;
        SELECT MAX(p.versao) into versao FROM produtos p where p.id = id_produto;
        --RAISE NOTICE 'quantidade - % , compra_id - %,produto_id - %,versao - %,vendedor- %',quant,idd,id_produto,versao , vendedor ;
        INSERT INTO itens (quantidade,compra_id,produto_id,versao_produto,vendedor_id) VALUES (quant,idd,id_produto,versao , vendedor );


    END LOOP;
    
    --UPDATE !!
    UPDATE compras SET compra_valor = preco_total WHERE compra_id = idd;
END;
$$ LANGUAGE plpgsql;


-- RATINGS ================================================================================================
drop FUNCTION user_bought_product;
CREATE  FUNCTION user_bought_product(comprador INT, produto INTEGER)
RETURNS INT
AS
$$
DECLARE 
    resultado INT;
    versao INT := 0;
BEGIN
    SELECT produto_versao INTO versao FROM itens i 
    WHERE i.comprador_id = comprador AND i.produto = produto
    ORDER BY i.produto_versao DESC;
    IF idd <= 0 THEN
        resultado = 0;
    ELSE resultado = versao;
    END IF;
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

drop function add_rating;
CREATE FUNCTION add_rating(valor INT, comentario VARCHAR, comprador INT, produto INT, versao INT)
RETURNS VOID
AS
$$
DECLARE
    BEGIN
        INSERT INTO ratings (valor, comentario, comprador_id, produto_id, produto_versao) VALUES (valor, comentario, comprador, produto, versao);
END;
$$ LANGUAGE plpgsql;

-- COMENTARIOS ============================================================================================
drop function add_comentario1;
CREATE  FUNCTION add_comentario1(texto VARCHAR, utilizador INT, produto INT)
RETURNS VOID
AS
$$
DECLARE
BEGIN
    INSERT INTO comentario (texto, utilizador_id, produto_id, produto_versao) VALUES (texto, utilizador, produto, max_versao(produto));

END;
$$ LANGUAGE plpgsql;

drop function add_comentario2;
CREATE  FUNCTION add_comentario2(texto VARCHAR, utilizador INT, produto INT, comentario_pai INT)
RETURNS VOID
AS
$$
DECLARE
BEGIN
    INSERT INTO comentario (texto, utilizador_id, produto_id, comentario_pai_id, produto_versao) VALUES (texto, utilizador, produto, comentario_pai, max_versao(produto));

END;
$$ LANGUAGE plpgsql;

-- NOTIFICACOES ==============================================================================================================

CREATE OR REPLACE FUNCTION max_id_notificacoes()
RETURNS INT
AS
$$
DECLARE
    idd INT;
BEGIN
    SELECT MAX(id) INTO idd FROM notificacoes; 
    IF idd is NULL THEN
     idd := 0;
    END IF;
    RETURN idd;
END;
$$ LANGUAGE plpgsql;

--TODO: fazer uma funcao que devolva todas as notificacoes do user

-- PRODUTOS ===========================================================================================

-- Devolve o id do produto dando o seu nome e o id do vendedor
    --QUESTION: Se por quealquer razao se colocar mos a guardo o historico da ram, etc de um produto teremos que colocar a busca pela versao tb
-- TODO: 
DROP FUNCTION ID_PRODUTO;
CREATE OR REPLACE FUNCTION ID_PRODUTO(string VARCHAR, vendedor INT)
RETURNS INT
AS
$$
DECLARE
    idd INT;
BEGIN
    SELECT id INTO idd FROM produtos
    GROUP BY id HAVING vendedor_id = vendedor and produtos.nome like string ; 
    RETURN idd;
END;
$$ LANGUAGE plpgsql;

--Devolve max id da tabela produtos
CREATE OR REPLACE FUNCTION max_id()
RETURNS INT
AS
$$
DECLARE
    idd INT;
BEGIN
    SELECT MAX(id) INTO idd FROM produtos; 
    IF idd is NULL THEN
     idd := 0;
    END IF;
    RETURN idd;
END;
$$ LANGUAGE plpgsql;

--Devolve max versao de um produto
CREATE OR REPLACE FUNCTION max_versao(produto INT)
RETURNS INT
AS
$$
DECLARE
    ver INT;
BEGIN
    SELECT MAX(versao) INTO ver FROM produtos p WHERE p.id = produto; 
    IF ver is NULL THEN
     ver := 0;
    END IF;
    RETURN ver;
END;
$$ LANGUAGE plpgsql;

-- insere um computador
DROP FUNCTION add_computador;      
CREATE  FUNCTION add_computador(id_produto INT,Versao INT,Nomepc VARCHAR,Descricao VARCHAR,Preco FLOAT,Stock INTEGER,ID_VEND INTEGER,Processador VARCHAR,Ram INTEGER,Rom INTEGER,Grafica VARCHAR)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO produtos (nome,id, descricao, preco, stock, versao,vendedor_id) VALUES (Nomepc,id_produto, Descricao, Preco, Stock,Versao,ID_VEND);
        INSERT INTO computadores (processador, ram, rom, grafica, produto_id,produto_versao) VALUES (Processador, Ram, Rom, Grafica, id_produto,Versao);
END;
$$ LANGUAGE plpgsql;

-- insere um telemovel
DROP FUNCTION add_telemovel; 
CREATE  FUNCTION add_telemovel(id_produto INT,Versao INT,Nome_telemovel VARCHAR,Descricao VARCHAR,Preco FLOAT,Stock INTEGER,ID_VEND INTEGER,Tamanho FLOAT,Ram INTEGER,Rom INTEGER)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO produtos (nome,id, descricao, preco, stock, versao,vendedor_id) VALUES (Nome_telemovel,id_produto, Descricao, Preco, Stock,Versao,ID_VEND);
        INSERT INTO telemoveis (tamanho, ram, rom, produto_id,produto_versao) VALUES (Tamanho, Ram, Rom, id_produto,Versao);
END;
$$ LANGUAGE plpgsql;

-- insere uma televisao
DROP FUNCTION add_televisao; 
CREATE  FUNCTION add_televisao(id_produto INT,Versao INT,Nometv VARCHAR,Descricao VARCHAR,Preco FLOAT,Stock INTEGER,ID_VEND INTEGER,Tamanho FLOAT,Resolucao INTEGER)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO produtos (nome,id, descricao, preco, stock, versao,vendedor_id) VALUES (Nometv,id_produto, Descricao, Preco, Stock,Versao,ID_VEND);
        INSERT INTO televisoes (tamanho, resolucao, produto_id,produto_versao) VALUES (Tamanho, Resolucao, id_produto,Versao);
END;
$$ LANGUAGE plpgsql;

-- UTILIZADORES ======================================================================================

-- insere um vendedor
CREATE OR REPLACE FUNCTION ADD_VENDEDOR(userName VARCHAR,pass VARCHAR,Nome VARCHAR,Nif INTEGER)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO utilizadores (username, password, nome) VALUES (userName, pass, Nome);
        INSERT INTO vendedores (utilizador_id,nif) VALUES (ID_USER(userName),Nif);
END;
$$ LANGUAGE plpgsql;

-- insere um comprador
CREATE OR REPLACE FUNCTION ADD_COMPRADOR(userName VARCHAR,pass VARCHAR,Nome VARCHAR,Morada VARCHAR)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO utilizadores (username, password, nome) VALUES (userName, pass, Nome);
        INSERT INTO compradores (utilizador_id,morada) VALUES (ID_USER(userName),Morada);
END;
$$ LANGUAGE plpgsql;

-- insere um admin
CREATE OR REPLACE FUNCTION ADD_ADMIN(userName VARCHAR,pass VARCHAR,Nome VARCHAR)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO utilizadores (username, password, nome) VALUES (userName, pass, Nome);
        INSERT INTO admins (utilizador_id) VALUES (ID_USER(userName));
END;
$$ LANGUAGE plpgsql;

-- Devolve o id do vendedor dando o seu username
CREATE OR REPLACE FUNCTION ID_VENDEDOR(UN VARCHAR)
RETURNS INT
AS
$$
DECLARE
    id INT;
BEGIN
    SELECT utilizador_id INTO id FROM vendedores, utilizadores u
    WHERE u.username like UN and u.id = vendedores.utilizador_id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

-- Devolve o id do user dando o seu username
CREATE OR REPLACE FUNCTION ID_USER(UN VARCHAR)
RETURNS INT
AS
$$
DECLARE
    id INT;
BEGIN
    SELECT utilizadores.id INTO id FROM utilizadores
    WHERE utilizadores.username = UN;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

