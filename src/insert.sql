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
        tipo := 'compradores';
        cond:=1;
    END IF;
    IF cond = 0  THEN
        SELECT u.id INTO idd FROM utilizadores u, vendedores v WHERE u.id = v.utilizador_id AND  u.username = US and u.password like pass ;
        IF  idd > 0  THEN
            tipo := 'vendedores';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0  THEN
        SELECT u.id INTO idd FROM utilizadores u, admins a WHERE  u.id = a.utilizador_id AND u.username = US and u.password like pass ;
        IF  idd > 0  THEN
            tipo:= 'admins';
            cond:=1;
        END IF;
    END IF;
    IF cond = 0 THEN 
        tipo:= 'ERRO';
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
    id INT := -1;
BEGIN 
    SELECT u.id  FROM utilizadores u
    WHERE u.username = UN;
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

--TODO: --Devolve maxima versao  da tabela produtos
-- CREATE OR REPLACE FUNCTION max_versao(string VARCHAR, vendedor INT)
-- RETURNS INT
-- AS
-- $$
-- DECLARE
--     idd INT;
-- BEGIN
--     SELECT MAX(versao) INTO idd FROM produtos
--     WHERE produtos.nome like string and produtos.vendedor_id = vendedor  ; 
--     RETURN idd;
-- END;
-- $$ LANGUAGE plpgsql;


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
CREATE  FUNCTION add_computador(Versao INT,Nomepc VARCHAR,Descricao VARCHAR,Preco FLOAT,Stock INTEGER,nomeVendedor VARCHAR,Processador VARCHAR,Ram INTEGER,Rom INTEGER,Grafica VARCHAR)
RETURNS void
AS
$$
DECLARE
    id_produto INTEGER;
    BEGIN
        id_produto := max_id() +1;
        INSERT INTO produtos (nome,id, descricao, preco, stock, versao,vendedor_id) VALUES (Nomepc,id_produto, Descricao, Preco, Stock,Versao,ID_VENDEDOR(nomeVendedor));
        INSERT INTO computadores (processador, ram, rom, grafica, produto_id) VALUES (Processador, Ram, Rom, Grafica, id_produto);
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
SELECT add_computador(1,'Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,'techmania','Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT add_computador(1,'Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,'infortech','Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT add_computador(1,'Computador2', 'Ryzen9 5900x 32GB RTX 3090', 4000, 1,'infortech','Ryzen9 5900x', 32, 1024, 'RTX 3090');

-- Telemoveis



-- Televisoes