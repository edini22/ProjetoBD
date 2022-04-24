-- FUNCOES ==========================================================================

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

-- Devolve o id do vendedor dando o seu username
CREATE OR REPLACE FUNCTION ID_VENDEDOR(UN VARCHAR)
RETURNS INT
AS
$$
DECLARE
    id INT;
BEGIN
    SELECT utilizador_id INTO id FROM vendedores, utilizadores u
    WHERE u.username = UN and u.id = vendedores.utilizador_id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

-- Devolve o id do produto dando o seu nome e o id do vendedor
-- TODO: 
-- CREATE OR REPLACE FUNCTION ID_PRODUTO(string VARCHAR, vendedor INT)
-- RETURNS INT
-- AS
-- $$
-- DECLARE
--     idd INT;
-- BEGIN
--     SELECT id INTO idd FROM produtos
--     WHERE produtos.nome = string; 
--     RETURN idd;
-- END;
-- $$ LANGUAGE plpgsql;


-- Users ============================================================================

--Admins
INSERT INTO utilizadores (username, password, nome) VALUES ('edini', 'password01', 'Eduardo Figueiredo');
INSERT INTO admins (utilizador_id) VALUES (ID_USER('edini'));
INSERT INTO utilizadores (username, password, nome) VALUES ('fabirino', 'password02', 'Fábio Santos');
INSERT INTO admins (utilizador_id) VALUES (ID_USER('fabirino'));


-- Compradores
INSERT INTO utilizadores (username, password, nome) VALUES ('josem', 'password03', 'José Maria');
INSERT INTO compradores (utilizador_id, morada) VALUES (ID_USER('josem'), 'Rua da Catraia, Lisboa');
INSERT INTO utilizadores (username, password, nome) VALUES ('anamargarida', 'password04', 'Ana Margarida');
INSERT INTO compradores (utilizador_id, morada) VALUES (ID_USER('anamargarida'), 'Avenida das Laranjeiras, Anadia');

-- Vendedores
INSERT INTO utilizadores (username, password, nome) VALUES ('infortech', 'password05', 'InforTech LDA');
INSERT INTO vendedores (utilizador_id, nif) VALUES (ID_USER('infortech'), 521376896);
INSERT INTO utilizadores (username, password, nome) VALUES ('techmania', 'password06', 'TechMania');
INSERT INTO vendedores (utilizador_id, nif) VALUES (ID_USER('techmania'), 624786152);



-- Produtos =========================================================================

-- Computadores

INSERT INTO produtos (nome, descricao, preco, stock, vendedor_id) VALUES ('Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,ID_VENDEDOR('techmania'));
-- INSERT INTO computadores (processador, ram, rom, grafica, produto_id) VALUES ('Intel i7 12700k', 16, 1024, 'RTX 3060', ID_PRODUTO('Computador1'));
-- INSERT INTO produtos (nome, descricao, preco, stock, vendedor_id) VALUES ('Computador2', 'Ryzen9 5900x 32GB RTX 3090', 4000, 1,ID_VENDEDOR('infortech'));
INSERT INTO produtos (nome, descricao, preco, stock, vendedor_id) VALUES ('Computador1', 'Intel i7 16GB RTX 3060', 1300, 3,ID_VENDEDOR('infortech'));


-- Telemoveis



-- Televisoes