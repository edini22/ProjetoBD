SELECT * FROM utilizadores;
SELECT * FROM compradores;
SELECT * FROM vendedores;
SELECT * FROM admins;

SELECT * FROM produtos;
SELECT * FROM televisoes;

SELECT * from comentarios;

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

SELECT * FROM notificacoes;
SELECT notificacao_vista(3);

SELECT * FROM itens;

SELECT produto_id ,produto_versao  FROM ratings where produto_id = 1;

SELECT MAX(i.versao_produto)  FROM itens i ,compras c WHERE i.compra_id = c.compra_id and i.produto_id = 1 and c.comprador_id = 3;

SELECT comentario_pai_id  FROM comentarios WHERE id = 1;

SELECT utilizador_id FROM comentarios WHERE id = 6;

SELECT p.id  FROM produtos p WHERE p.id = 1 ORDER BY p.versao DESC;