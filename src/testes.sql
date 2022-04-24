SELECT * FROM utilizadores;
SELECT * FROM compradores;
SELECT * FROM vendedores;
SELECT * FROM admins;

SELECT * FROM produtos;
SELECT * FROM computadores;

SELECT id FROM produtos
WHERE produtos.nome like 'Computador1';


SELECT id FROM produtos
    WHERE produtos.nome like 'Computador1' and produtos.vendedor_id = ID_VENDEDOR('infortech'); 
