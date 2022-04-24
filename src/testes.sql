SELECT * FROM utilizadores;
SELECT * FROM compradores;
SELECT * FROM vendedores;
SELECT * FROM admins;

SELECT * FROM produtos;

SELECT id FROM produtos
WHERE produtos.nome = 'Computador1';

-- FIXME: este select mostra os 2 ids
SELECT id FROM produtos, vendedores v
WHERE produtos.nome = 'Computador1' AND v.utilizador_id = ID_VENDEDOR('infortech');
