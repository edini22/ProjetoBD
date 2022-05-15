--COMPRA============================================================================ CURRENT_DATE
DROP FUNCTION add_item; 
CREATE  FUNCTION add_item(Quantidade INT,Compra_id INTEGER,Produto_id INTEGER,Versao_produto INTEGER)
RETURNS void
AS
$$
DECLARE
    vendedor INTEGER ;
    versao INTEGER;
    BEGIN
        SELECT p.vendedor_id into vendedor  FROM produtos p where p.id = Produto_id;
        SELECT MAX(p.versao) into versao FROM produtos p where p.id = Produto_id;
        INSERT INTO itens (quantidade,compra_id,produto_id,versao_produto,vendedor_id) VALUES (Quantidade,Compra_id,Produto_id,versao , vendedor );
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION add_compra; 
CREATE  FUNCTION add_compra(js json ,Id_comprador INTEGER)
RETURNS void
AS
$$
DECLARE
preco_total FLOAT := 0;
BEGIN
    --LOOP COM O JSON   #
    --VERIFICAR SE EXISTE ESSE PRODUTO !!


    INSERT INTO compra (compra_valor,compra_data,comprador_id) VALUES (preco_total,CURRENT_DATE,Id_comprador);
 
END;
$$ LANGUAGE plpgsql;
-- FUNCOES ==========================================================================

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
    idd INT :=0;
BEGIN 
    SELECT p.id INTO idd FROM produtos p, computadores c WHERE p.id = c.produto_id;
    IF idd > 0  THEN
        tipo := 'computador';
        cond:=1;
    END IF;
    IF cond = 0  THEN
        SELECT p.id INTO idd FROM produtos p, telemoveis t WHERE p.id = t.produto_id;
        IF  idd > 0  THEN
            tipo := 'telemovel';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0  THEN
        SELECT p.id INTO idd FROM produtos p, televisao t WHERE  p.id = t.produto_id;
        IF  idd > 0  THEN
            tipo:= 'televisao';
            cond:=1;
        END IF;
    END IF;

    RETURN tipo;
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


-- Users ============================================================================

--Admins
SELECT ADD_ADMIN('edini', 'password01', 'Eduardo Figueiredo');
SELECT ADD_ADMIN('fabirino', 'password02', 'Fábio Santos');


-- Compradores
SELECT ADD_COMPRADOR('josem', 'password03', 'José Maria','Rua da Catraia, Lisboa');
SELECT ADD_COMPRADOR('anamargarida', 'password04', 'Ana Margarida','Avenida das Laranjeiras, Anadia');

-- Vendedores
SELECT ADD_VENDEDOR('infortech', 'password05', 'InforTech LDA',521376896);
SELECT ADD_VENDEDOR('techmania', 'password06', 'TechMania',624786152);


-- Produtos =========================================================================

-- -- Computadores
SELECT add_computador(max_id() +1,1,'Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,5,'Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT add_computador(max_id() +1,1,'Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,6,'Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT add_computador(max_id() +1,1,'Computador2', 'Ryzen9 5900x 32GB RTX 3090', 4000, 1,6,'Ryzen9 5900x', 32, 1024, 'RTX 3090');

-- Telemoveis

SELECT add_telemovel(max_id() +1,1, 'ePhone5', 'O melhor telemovel de sempre', 600, 5, 5, 5.2, 6, 128);
SELECT add_telemovel(max_id() +1,1, 'ecoPhone3', 'Melhor custo benificio', 200, 2, 6, 6, 4, 64);
SELECT add_telemovel(max_id() +1,1, 'Space4', 'Rapido como a luz', 999, 3, 5, 6.1, 8, 256);


-- Televisoes

SELECT add_televisao(max_id() +1,1, 'MyTV', 'Resolucao que nunca mais acaba', 1300, 4, 5, 60, 7680);
SELECT add_televisao(max_id() +1,1, 'CimenaTV', 'Como se estivesse no cinema', 700, 2, 6, 43, 3840);
SELECT add_televisao(max_id() +1,1, 'TVex', 'A melhor televisao de sempre', 500, 7, 5, 43, 3840);