SELECT * FROM utilizadores;
SELECT * FROM compradores;
SELECT * FROM vendedores;
SELECT * FROM admins;

SELECT * FROM produtos;
SELECT * FROM televisoes;
-- SELECT * FROM computadores c WHERE c.produto_id = 1 AND c.produto_versao = 1;

-- SELECT id FROM produtos
-- WHERE produtos.nome like 'Computador1';

-- SELECT LOGIN_VERIFY('edini','password01');
-- SELECT u.id  FROM utilizadores u, admins c WHERE  u.id = c.utilizador_id and u.username like 'edini' and u.password like 'password01' ;

-- SELECT id FROM produtos
--     WHERE produtos.nome like 'Computador1' and produtos.vendedor_id = ID_VENDEDOR('infortech'); 

-- SELECT  MAX(versao) FROM produtos  WHERE id = 1 ;

SELECT * from comentario;

SELECT * from compras;

SELECT add_compra('[
            {
                "product_id": 1,
                "quantidade" : 1
    
            },{
                "product_id": 2,
                "quantidade" : 1
            }
        ]
    ',3);

SELECT get_preco(5);    

SELECT * FROM itens;