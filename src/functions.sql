
-- LOGIN ===================================================================================================

--TODO: FAZER PROTECOES PARA VER SE ESSE PRODUTO AO INSERIR JA EXISTE!!!!

--retorna tipo de user se existir
DROP FUNCTION IF EXISTS LOGIN_VERIFY CASCADE;
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
DROP FUNCTION IF EXISTS GET_TIPO CASCADE;
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

DROP FUNCTION IF EXISTS get_preco CASCADE;
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


DROP FUNCTION IF EXISTS add_compra CASCADE; 
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
        INSERT INTO itens (quantidade,compra_id,produto_id,versao_produto,vendedor_id) VALUES (quant,idd,id_produto,versao , vendedor);


    END LOOP;
    
    --UPDATE !!
    UPDATE compras SET compra_valor = preco_total WHERE compra_id = idd;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS atualiza_stock CASCADE; 
CREATE FUNCTION atualiza_stock()
RETURNS TRIGGER 
AS $$
DECLARE
    quant INTEGER;
BEGIN
    SELECT stock into quant from produtos where id = NEW.produto_id and versao = NEW.versao_produto;
    if quant < NEW.quantidade then
        raise exception 'Quantidade indisponivel em stock  -  ';
    ELSE
        update produtos set stock = stock - NEW.quantidade --TODO: ver a cena do begin transaction
        where id = NEW.produto_id and versao = NEW.versao_produto;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS notificacao_vendedor CASCADE;
CREATE OR REPLACE FUNCTION notificacao_vendedor()
RETURNS TRIGGER
AS $$
DECLARE 
mensagem varchar;
id_comprador INT;
    BEGIN

    SELECT comprador_id INTO id_comprador FROM compras where compra_id = NEW.compra_id;
    mensagem := concat('O user ',id_comprador,' comprou ',NEW.quantidade,' produto(s) com a referencia ',NEW.produto_id,'.');

    INSERT INTO notificacoes(data,texto,utilizador_id) VALUES(CURRENT_DATE,mensagem,NEW.vendedor_id);
    RETURN NEW;
    END
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS notificacao_comprador CASCADE;
CREATE OR REPLACE FUNCTION notificacao_comprador()
RETURNS TRIGGER
AS $$
DECLARE 
cur CURSOR for select quantidade ,produto_id from itens WHERE compra_id = NEW.compra_id;
mensagem varchar;

row_item record;
    BEGIN

    mensagem := concat('Voce comprou ');
    OPEN cur;
    LOOP
    FETCH cur into row_item;
    exit when not found;
    mensagem := concat(mensagem,row_item.quantidade,' produto(s) de id:',row_item.produto_id,', ');
    end loop;
    close cur;
    mensagem := concat(mensagem,'e ficou num total de ',NEW.compra_valor,' euros.');

    INSERT INTO notificacoes(data,texto,utilizador_id) VALUES(CURRENT_DATE,mensagem,NEW.comprador_id);
    RETURN NEW;
    END
$$ LANGUAGE plpgsql;


-- RATINGS ================================================================================================
drop FUNCTION IF EXISTS user_bought_product CASCADE;
CREATE  FUNCTION user_bought_product(comprador INT, produto INTEGER)
RETURNS INT
AS
$$
DECLARE 
    resultado INT;
    versao INT := 0;
BEGIN

    SELECT MAX(i.versao_produto) into  versao  FROM itens i ,compras c WHERE i.compra_id = c.compra_id and i.produto_id = produto and c.comprador_id = comprador;

    IF versao <= 0 THEN
        resultado = 0;
    ELSE resultado = versao;
    END IF;
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

drop function IF EXISTS add_rating CASCADE;
CREATE FUNCTION add_rating(valor INT, comentario VARCHAR, comprador INT, produto INT, versao INT)
RETURNS VOID
AS
$$
DECLARE
    BEGIN
        INSERT INTO ratings (valor, comentario, comprador_id, produto_id, produto_versao) VALUES (valor, comentario, comprador, produto, versao);
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS notificacao_vendedor_rating CASCADE;
CREATE OR REPLACE FUNCTION notificacao_vendedor_rating()
RETURNS TRIGGER
AS $$
DECLARE 
mensagem varchar;
id_vendedor INT;
id_produto INT;
v_produto INT;
    BEGIN

    --OBTER id do vendedor do produto
    SELECT produto_id, produto_versao INTO id_produto, v_produto FROM ratings where produto_id = NEW.produto_id;
    SELECT vendedor_id INTO id_vendedor FROM produtos where id = id_produto and versao = v_produto;

    mensagem := concat('O user ',NEW.comprador_id,' avaliou o produto com id ',NEW.produto_id,' com ',NEW.valor,' estrela(s) e comentou: ',NEW.comentario,'.');

    INSERT INTO notificacoes(data,texto,utilizador_id) VALUES(CURRENT_DATE,mensagem,id_vendedor);
    RETURN NEW;
    END
$$ LANGUAGE plpgsql;

-- COMENTARIOS ============================================================================================
drop function IF EXISTS add_comentario1 CASCADE;
CREATE  FUNCTION add_comentario1(texto VARCHAR, utilizador INT, produto INT)
RETURNS VOID
AS
$$
DECLARE
BEGIN
    INSERT INTO comentarios (texto, utilizador_id, produto_id, produto_versao) VALUES (texto, utilizador, produto, max_versao(produto));

END;
$$ LANGUAGE plpgsql;

drop function IF EXISTS add_comentario2 CASCADE;
CREATE  FUNCTION add_comentario2(texto VARCHAR, utilizador INT, produto INT, comentario_pai INT)
RETURNS VOID
AS
$$
DECLARE
BEGIN
    INSERT INTO comentarios (texto, utilizador_id, produto_id, comentario_pai_id, produto_versao) VALUES (texto, utilizador, produto, comentario_pai, max_versao(produto));

END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS notificacao_comentario CASCADE;
CREATE OR REPLACE FUNCTION notificacao_comentario()
RETURNS TRIGGER
AS $$
DECLARE 
mensagem varchar;
id_coment_pai INT;
id_produto INT; 
v_produto INT;
id_vendedor INT;
    BEGIN

    SELECT comentario_pai_id into id_coment_pai FROM comentarios WHERE id = NEW.id;

    IF id_coment_pai is NULL THEN
        --OBTER id do vendedor do produto
        SELECT produto_id, produto_versao INTO id_produto, v_produto FROM comentarios where produto_id = NEW.produto_id;
        SELECT vendedor_id INTO id_vendedor FROM produtos where id = id_produto and versao = v_produto;

        mensagem := concat('O user ',NEW.utilizador_id,' comentou o produto com id ',NEW.produto_id,'.');

        INSERT INTO notificacoes(data,texto,utilizador_id) VALUES(CURRENT_DATE,mensagem,id_vendedor);
    ELSE
       SELECT utilizador_id into id_vendedor FROM comentarios WHERE id = id_coment_pai;

        mensagem := concat('O user ',NEW.utilizador_id,' respondeu ao seu comentario de id',id_coment_pai,'.');
        INSERT INTO notificacoes(data,texto,utilizador_id) VALUES(CURRENT_DATE,mensagem,id_vendedor);
    END IF;

    RETURN NEW;
    END
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

DROP FUNCTION IF EXISTS notificacao_vista CASCADE;
CREATE OR REPLACE FUNCTION notificacao_vista(User_idd INT)
RETURNS VOID
AS $$
DECLARE 
cur CURSOR for SELECT n.vista,n.id from notificacoes n WHERE n.utilizador_id = User_idd and n.vista = 'false' ;
row_item record;
    BEGIN

    OPEN cur;
    LOOP
    FETCH cur into row_item;
    exit when not found;

    UPDATE notificacoes SET vista = 'true' where row_item.id = id; 

    end loop;
    close cur;

    END
$$ LANGUAGE plpgsql;

--TODO: fazer uma funcao que devolva todas as notificacoes do user

-- PRODUTOS ===========================================================================================

-- Devolve o id do produto dando o seu nome e o id do vendedor
    --QUESTION: Se por quealquer razao se colocar mos a guardo o historico da ram, etc de um produto teremos que colocar a busca pela versao tb
-- TODO: 
DROP FUNCTION IF EXISTS ID_PRODUTO CASCADE;
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
DROP FUNCTION IF EXISTS add_computador CASCADE;      
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
DROP FUNCTION IF EXISTS add_telemovel CASCADE; 
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
DROP FUNCTION IF EXISTS add_televisao CASCADE; 
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

-- Devolve o tipo do produto atraves do user
DROP FUNCTION IF EXISTS GET_PRODUCT CASCADE;
CREATE OR REPLACE FUNCTION GET_PRODUCT(ID_PRODUTO INT)
RETURNS JSONB
AS
$$
DECLARE
    idd INT :=-1;
    js JSONB ;
    js_price JSONB;
    cur CURSOR for SELECT p.preco,p.versao,p.data FROM produtos p WHERE p.id = ID_PRODUTO ORDER BY p.versao DESC;
    cur2 CURSOR for SELECT c.texto FROM comentarios c WHERE c.produto_id = ID_PRODUTO;
    row_item record;
    m_versao INT;
    n_comentarios INT;
    n_ratings INT;
    valor_rating INT :=0;
    mensagem VARCHAR;
    mens VARCHAR;
    coun INT :=0;
BEGIN 

    SELECT p.id INTO idd FROM produtos p WHERE p.id = ID_PRODUTO;
    IF idd > 0  THEN
        SELECT MAX(p.versao) INTO m_versao FROM produtos p WHERE p.id = ID_PRODUTO;
        SELECT COUNT(id) into n_comentarios FROM comentarios WHERE produto_id = ID_PRODUTO ;
        SELECT COUNT(valor) into n_ratings FROM ratings WHERE produto_id = ID_PRODUTO ;
        SELECT row_to_json(produtos) into js  FROM(SELECT id,nome,stock,versao,descricao,vendedor_id FROM produtos ) produtos WHERE id = ID_PRODUTO and versao = m_versao;

        IF n_comentarios = 0 AND n_ratings = 0 THEN
            js :=  js::jsonb || '{"comentarios": "Nao existem comentarios feitos acerca deste produtos"}'::jsonb;
            js :=  js::jsonb || '{"rating": "Nao existem ratings feitos para este produto"}'::jsonb;

        ELSE 
            SELECT AVG(valor) into valor_rating FROM ratings WHERE produto_id = ID_PRODUTO ;
            IF n_comentarios = 0 THEN
                js :=  js::jsonb || '{"comentarios": "Nao existem comentarios feitos acerca deste produtos"}'::jsonb;
                js :=  js::jsonb || json_build_object('rating',valor_rating)::jsonb;
            ELSE 
                js :=  js::jsonb || json_build_object('rating',valor_rating)::jsonb;
                OPEN cur2;
                LOOP
                FETCH cur2 into mens;
                exit when not found;
                raise NOTICE '%',mens;
                
                mensagem := concat(mensagem,', ',mens);
                

                end loop;
                js_price := json_build_object('comentarios',mensagem);
                js :=  js::jsonb || js_price::jsonb;
                close cur2;

            END IF;

        END IF;

        OPEN cur;
        LOOP
        FETCH cur into row_item;
        exit when not found;

        IF row_item.versao = m_versao THEN
            mensagem := concat(row_item.data,' - ',row_item.preco);
        ELSE
            mensagem := concat(mensagem,', ',row_item.data,' - ',row_item.preco);
        END IF;
        raise NOTICE '%',mensagem;

        end loop;
        js_price := json_build_object('preco',mensagem);
        js :=  js::jsonb || js_price::jsonb;
        close cur;

    END IF;

    RETURN js;
END;
$$ LANGUAGE plpgsql;

