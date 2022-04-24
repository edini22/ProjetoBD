-- FUNCOES ==========================================================================

--TODO: FAZER PROTECOES PARA VER SE ESSE PRODUTO AO INSERIR JA EXISTE!!!!

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
-- TODO: 
CREATE OR REPLACE FUNCTION ID_PRODUTO(string VARCHAR, vendedor INT)
RETURNS INT
AS
$$
DECLARE
    idd INT;
BEGIN
    SELECT id INTO idd FROM produtos
    WHERE produtos.nome like string and produtos.vendedor_id = vendedor; 
    RETURN idd;
END;
$$ LANGUAGE plpgsql;

-- insere um computador
CREATE OR REPLACE FUNCTION ADD_COMPUTADOR(Nome VARCHAR,Descricao VARCHAR,Preco FLOAT,Stock INTEGER,nomeVendedor VARCHAR,Processador VARCHAR,Ram INTEGER,Rom INTEGER,Grafica VARCHAR)
RETURNS void
AS
$$
DECLARE
    BEGIN
        INSERT INTO produtos (nome, descricao, preco, stock, vendedor_id) VALUES (Nome, Descricao, Preco, Stock,ID_VENDEDOR(nomeVendedor));
        INSERT INTO computadores (processador, ram, rom, grafica, produto_id) VALUES (Processador, Ram, Rom, Grafica, ID_PRODUTO(Nome,ID_VENDEDOR(nomeVendedor)));
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




-- -- Produtos =========================================================================

-- -- Computadores
SELECT ADD_COMPUTADOR('Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,'techmania','Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT ADD_COMPUTADOR('Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,'infortech','Intel i7 12700k', 16, 1024, 'RTX 3060');
SELECT ADD_COMPUTADOR('Computador2', 'Ryzen9 5900x 32GB RTX 3090', 4000, 1,'infortech','Ryzen9 5900x', 32, 1024, 'RTX 3090');

-- Telemoveis



-- Televisoes